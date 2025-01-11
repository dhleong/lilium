use tower_lsp::{
    jsonrpc::{self, Error},
    lsp_types::{
        CompletionItem, CompletionItemKind, CompletionOptions, CompletionParams,
        CompletionResponse, CompletionTextEdit, ExecuteCommandOptions, ExecuteCommandParams,
        InitializeParams, InitializeResult, InitializedParams, InsertTextFormat, InsertTextMode,
        ServerCapabilities, ServerInfo, TextDocumentSyncKind, TextEdit, WorkDoneProgressOptions,
    },
    Client, LanguageServer,
};

use crate::{
    adapters::{Adapter, InitializableAdapter},
    documents::Documents,
    progress::ProgressReporter,
};

#[derive(Debug)]
pub struct Backend {
    client: Client,
    adapter: InitializableAdapter,
    documents: Documents,
}

impl Backend {
    pub fn with_client(client: Client) -> Self {
        Self {
            client,
            adapter: InitializableAdapter::default(),
            documents: Documents::default(),
        }
    }
}

#[tower_lsp::async_trait]
impl LanguageServer for Backend {
    async fn initialize(&self, params: InitializeParams) -> jsonrpc::Result<InitializeResult> {
        if let Some(root) = params.root_uri {
            let path = root.to_file_path().unwrap();
            self.adapter
                .set_root(path.to_string_lossy().to_string())
                .await;
        }

        Ok(InitializeResult {
            server_info: Some(ServerInfo {
                name: env!("CARGO_PKG_NAME").to_string(),
                version: Some(env!("CARGO_PKG_VERSION").to_string()),
            }),
            capabilities: ServerCapabilities {
                text_document_sync: Some(tower_lsp::lsp_types::TextDocumentSyncCapability::Kind(
                    TextDocumentSyncKind::FULL,
                )),

                completion_provider: Some(CompletionOptions {
                    resolve_provider: Some(false),
                    trigger_characters: Some(vec!["@".to_string(), "#".to_string()]),
                    work_done_progress_options: WorkDoneProgressOptions {
                        work_done_progress: Some(true),
                    },
                    all_commit_characters: None,
                    completion_item: None,
                }),

                execute_command_provider: Some(ExecuteCommandOptions {
                    commands: vec!["lilium.info".to_string()],
                    work_done_progress_options: WorkDoneProgressOptions {
                        work_done_progress: Some(true),
                    },
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

    async fn did_open(&self, params: tower_lsp::lsp_types::DidOpenTextDocumentParams) {
        self.documents.did_open(&params)
    }

    async fn did_change(&self, params: tower_lsp::lsp_types::DidChangeTextDocumentParams) {
        self.documents.did_change(&params)
    }

    async fn completion(
        &self,
        params: CompletionParams,
    ) -> jsonrpc::Result<Option<CompletionResponse>> {
        let context = if let Some(context) = self.documents.build_completion_context(&params) {
            context
        } else {
            return Ok(None);
        };

        let tickets = self.adapter.tickets(&context).await?;

        let items = tickets
            .into_iter()
            .map(|mut ticket| {
                let is_simple_ticket_ref = ticket.reference.starts_with('#');

                // NOTE: Including the prefix in the filter_text like this
                // is important so clients can continue to match even if
                // the prefix isn't included in the final output
                // (IE: !is_simple_ticket_ref)
                CompletionItem {
                    filter_text: Some(format!(
                        "{prefix}{title} {id}",
                        prefix = '#', // TODO
                        title = ticket.title,
                        id = ticket.id
                    )),
                    label: format!("{} {}", ticket.provider_prefix, ticket.title),
                    label_details: None,
                    kind: Some(CompletionItemKind::REFERENCE),
                    detail: ticket.description,
                    sort_text: None, // TODO ?
                    insert_text: if is_simple_ticket_ref {
                        Some(ticket.reference.split_off(1))
                    } else {
                        None
                    },
                    text_edit: if is_simple_ticket_ref {
                        None
                    } else {
                        Some(CompletionTextEdit::Edit(TextEdit {
                            range: context.completion_range(),
                            new_text: ticket.reference,
                        }))
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

    async fn execute_command(
        &self,
        params: ExecuteCommandParams,
    ) -> jsonrpc::Result<Option<serde_json::Value>> {
        let cmd: &str = &params.command;
        match cmd {
            "lilium.info" => {
                let uri = params
                    .arguments
                    .into_iter()
                    .next()
                    .ok_or_else(|| Error::invalid_params("Missing uri"))?;

                let serde_json::Value::String(uri) = uri else {
                    return Err(Error::invalid_params("uri must be a string"));
                };

                let info = self.info(uri).await;
                Ok(Some(info.into()))
            }
            _ => Err(Error::invalid_request()),
        }
    }
}

impl Backend {
    async fn info(&self, _uri: String) -> String {
        self.adapter.describe().await
    }
}
