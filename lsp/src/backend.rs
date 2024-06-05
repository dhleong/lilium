use tower_lsp::{
    jsonrpc,
    lsp_types::{
        CompletionItem, CompletionItemKind, CompletionOptions, CompletionParams,
        CompletionResponse, InitializeParams, InitializeResult, InitializedParams,
        InsertTextFormat, InsertTextMode, Range, ServerCapabilities, ServerInfo,
        WorkDoneProgressOptions,
    },
    Client, LanguageServer,
};

use crate::{
    adapters::{Adapter, InitializableAdapter},
    progress::ProgressReporter,
};

#[derive(Debug)]
pub struct Backend {
    client: Client,
    adapter: InitializableAdapter,
}

impl Backend {
    pub fn with_client(client: Client) -> Self {
        Self {
            client,
            adapter: InitializableAdapter::default(),
        }
    }
}

#[tower_lsp::async_trait]
impl LanguageServer for Backend {
    async fn initialize(&self, _: InitializeParams) -> jsonrpc::Result<InitializeResult> {
        Ok(InitializeResult {
            server_info: Some(ServerInfo {
                name: env!("CARGO_PKG_NAME").to_string(),
                version: Some(env!("CARGO_PKG_VERSION").to_string()),
            }),
            capabilities: ServerCapabilities {
                completion_provider: Some(CompletionOptions {
                    resolve_provider: Some(false),
                    trigger_characters: Some(vec!["@".to_string(), "#".to_string()]),
                    work_done_progress_options: WorkDoneProgressOptions {
                        work_done_progress: Some(true),
                    },
                    all_commit_characters: None,
                    completion_item: None,
                }),
                ..ServerCapabilities::default()
            },
        })
    }

    async fn initialized(&self, _: InitializedParams) {
        let progress =
            ProgressReporter::start(&self.client, "initialize", "Initializing Lilium", None).await;

        self.adapter.initialize(&progress).await;

        progress.end(Some("Ready!".to_string())).await;
    }

    async fn shutdown(&self) -> jsonrpc::Result<()> {
        Ok(())
    }

    async fn completion(
        &self,
        params: CompletionParams,
    ) -> jsonrpc::Result<Option<CompletionResponse>> {
        let tickets = self.adapter.tickets().await?;

        let items = tickets
            .into_iter()
            .map(|mut ticket| {
                CompletionItem {
                    filter_text: Some(format!(
                        "{title} #{id}",
                        title = ticket.title,
                        id = ticket.id
                    )),
                    label: ticket.title,
                    label_details: None,
                    kind: Some(CompletionItemKind::TEXT),
                    detail: ticket.description,
                    sort_text: None, // TODO ?
                    insert_text: if ticket.reference.starts_with('#') {
                        Some(ticket.reference.split_off(1))
                    } else {
                        None
                    },
                    text_edit: if ticket.reference.starts_with('#') {
                        None
                    } else {
                        Some(tower_lsp::lsp_types::CompletionTextEdit::Edit(
                            tower_lsp::lsp_types::TextEdit {
                                range: Range {
                                    // TODO: Compute position of #
                                    start: tower_lsp::lsp_types::Position {
                                        line: params.text_document_position.position.line,
                                        character: params
                                            .text_document_position
                                            .position
                                            .character
                                            .saturating_sub(1),
                                    },
                                    end: params.text_document_position.position,
                                },
                                new_text: ticket.reference,
                            },
                        ))
                    },
                    insert_text_format: Some(InsertTextFormat::PLAIN_TEXT),
                    insert_text_mode: Some(InsertTextMode::AS_IS),
                    ..CompletionItem::default()
                }
            })
            .collect();

        let response = CompletionResponse::List(tower_lsp::lsp_types::CompletionList {
            is_incomplete: true,
            items,
        });
        Ok(Some(response))
    }
}
