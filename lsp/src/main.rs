use adapters::{composite::CompositeAdapter, Adapter, AdapterParams};
use clap::Parser;
use cli::{Cli, Commands};
use completion::CompletionContext;
use tower_lsp::{LspService, Server};

use backend::Backend;

pub mod adapters;
mod backend;
mod cli;
mod completion;
pub mod documents;
mod progress;

async fn run_lsp() {
    let stdin = tokio::io::stdin();
    let stdout = tokio::io::stdout();
    let (service, socket) = LspService::build(Backend::with_client).finish();

    Server::new(stdin, stdout, socket).serve(service).await;
}

async fn print_tickets(root: Option<String>) {
    let adapter = CompositeAdapter::create(AdapterParams { root }).await;
    let tickets = adapter
        .tickets(&CompletionContext {
            kind: completion::CompletionKind::Tickets,
            text: "".to_string(),
            prefix_start: tower_lsp::lsp_types::Position {
                line: 0,
                character: 0,
            },
        })
        .await;

    for ticket in &tickets {
        println!("{ticket:#?}");
    }
}

#[tokio::main]
async fn main() {
    let cli = Cli::parse();
    match cli.command {
        Commands::Lsp => run_lsp().await,
        Commands::Tickets => print_tickets(None).await,
    }
}
