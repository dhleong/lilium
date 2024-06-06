use dashmap::DashMap;
use ropey::{Rope, RopeSlice};
use tower_lsp::lsp_types::{
    CompletionParams, DidChangeTextDocumentParams, DidOpenTextDocumentParams, Position, Url,
};

use crate::completion::{CompletionContext, CompletionKind};

#[derive(Debug, Default)]
pub struct Documents {
    documents: DashMap<Url, Rope>,
}

impl Documents {
    pub fn did_open(&self, params: &DidOpenTextDocumentParams) {
        self.documents.insert(
            params.text_document.uri.clone(),
            Rope::from_str(&params.text_document.text),
        );
    }

    pub fn did_change(&self, params: &DidChangeTextDocumentParams) {
        self.documents.insert(
            params.text_document.uri.clone(),
            Rope::from_str(&params.content_changes[0].text),
        );
    }

    pub fn build_completion_context(&self, params: &CompletionParams) -> Option<CompletionContext> {
        let document = self
            .documents
            .get(&params.text_document_position.text_document.uri);

        let line = document.as_ref().map(|s| {
            s.line(
                params
                    .text_document_position
                    .position
                    .line
                    .try_into()
                    .unwrap(),
            )
        });

        completion_context_from_line(line, &params.text_document_position.position)
    }
}

fn completion_context_from_line(
    line: Option<RopeSlice>,
    position: &Position,
) -> Option<CompletionContext> {
    let before_cursor =
        line.and_then(|line| line.get_slice(0..position.character.try_into().unwrap()))?;

    let len = before_cursor.len_chars();
    let prefix_start = before_cursor
        .chars_at(len)
        .reversed()
        .enumerate()
        .find_map(|(offset, ch)| {
            if ch == '#' || ch == '@' {
                Some(len - offset - 1)
            } else {
                None
            }
        })?;

    println!("len={len} start={prefix_start}");

    Some(CompletionContext {
        kind: CompletionKind::Tickets,
        text: before_cursor.slice((prefix_start + 1)..len).to_string(),
        prefix_start: Position {
            line: position.line,
            character: prefix_start.try_into().unwrap(),
        },
    })
}

#[cfg(test)]
mod tests {
    use tower_lsp::lsp_types::Range;

    use super::*;

    fn completion_context_from_str(s: &str, character: u32) -> Option<CompletionContext> {
        completion_context_from_line(Some(s.into()), &Position { line: 0, character })
    }

    #[test]
    fn test_complete_empty_line() {
        let context = completion_context_from_str("", 0);

        assert_eq!(context, None);
    }

    #[test]
    fn test_complete_initial() {
        let context = completion_context_from_str("#", 1);

        assert_eq!(
            context,
            Some(CompletionContext {
                kind: CompletionKind::Tickets,
                text: "".to_string(),
                prefix_start: Position {
                    line: 0,
                    character: 0
                }
            })
        );
    }

    #[test]
    fn test_complete_start_of_line() {
        let context = completion_context_from_str("#taco", 5);

        assert_eq!(
            context,
            Some(CompletionContext {
                kind: CompletionKind::Tickets,
                text: "taco".to_string(),
                prefix_start: Position {
                    line: 0,
                    character: 0
                }
            })
        );

        assert_eq!(
            context.unwrap().completion_range(),
            Range {
                start: Position {
                    line: 0,
                    character: 0
                },
                end: Position {
                    line: 0,
                    character: 5
                },
            }
        )
    }

    #[test]
    fn test_complete_empty_end_of_line() {
        let context = completion_context_from_str("See: #", 6);

        assert_eq!(
            context,
            Some(CompletionContext {
                kind: CompletionKind::Tickets,
                text: "".to_string(),
                prefix_start: Position {
                    line: 0,
                    character: 5
                }
            })
        );
    }

    #[test]
    fn test_complete_end_of_line() {
        let context = completion_context_from_str("See: #taco", 10);

        assert_eq!(
            context,
            Some(CompletionContext {
                kind: CompletionKind::Tickets,
                text: "taco".to_string(),
                prefix_start: Position {
                    line: 0,
                    character: 5
                }
            })
        );
    }

    #[test]
    fn test_complete_middle_of_line() {
        let context = completion_context_from_str("See: #unrelated", 6);

        assert_eq!(
            context,
            Some(CompletionContext {
                kind: CompletionKind::Tickets,
                text: "".to_string(),
                prefix_start: Position {
                    line: 0,
                    character: 5
                }
            })
        );
    }
}
