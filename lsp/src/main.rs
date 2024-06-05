use backend::Backend;
use tower_lsp::{LspService, Server};

pub mod adapters;
mod backend;
mod progress;

#[tokio::main]
async fn main() {
    let stdin = tokio::io::stdin();
    let stdout = tokio::io::stdout();
    let (service, socket) = LspService::build(Backend::with_client).finish();

    Server::new(stdin, stdout, socket).serve(service).await;
}
