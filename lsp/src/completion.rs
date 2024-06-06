use tower_lsp::lsp_types::{Position, Range};

#[derive(Debug, PartialEq, Eq)]
pub enum CompletionKind {
    Tickets,
    Users,
}

#[derive(Debug, PartialEq, Eq)]
pub struct CompletionContext {
    pub kind: CompletionKind,
    pub text: String,
    pub prefix_start: Position,
}

impl CompletionContext {
    pub fn end(&self) -> Position {
        let text_len: u32 = self.text.len().try_into().unwrap();
        Position {
            line: self.prefix_start.line,
            character: self.prefix_end().character + text_len,
        }
    }

    pub fn prefix_end(&self) -> Position {
        // NOTE: So far all prefixes are single-char...
        Position {
            line: self.prefix_start.line,
            character: self.prefix_start.character + 1,
        }
    }

    pub fn prefix_range(&self) -> Range {
        Range {
            start: self.prefix_start,
            end: self.prefix_end(),
        }
    }

    pub fn completion_range(&self) -> Range {
        Range {
            start: self.prefix_start,
            end: self.end(),
        }
    }
}
