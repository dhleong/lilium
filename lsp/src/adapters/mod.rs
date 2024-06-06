use std::sync::Arc;

use async_trait::async_trait;
use tokio::sync::Mutex;
use tower_lsp::jsonrpc::{self, ErrorCode};

use crate::{completion::CompletionContext, progress::ProgressReporter};

use self::github::GithubAdapter;

mod github;

#[derive(Debug)]
pub struct Ticket {
    pub id: String,
    pub reference: String,
    pub title: String,
    pub description: Option<String>,
}

#[derive(Debug)]
pub enum AdapterError {
    NotInitialized,
    LoggedOut,
    Other(String),
}

impl From<AdapterError> for jsonrpc::Error {
    fn from(value: AdapterError) -> Self {
        Self {
            code: ErrorCode::InternalError,
            message: format!("{value:?}").into(),
            data: None,
        }
    }
}

#[async_trait]
pub trait Adapter {
    async fn tickets(&self, _context: &CompletionContext) -> Result<Vec<Ticket>, AdapterError> {
        Ok(vec![])
    }
}

#[derive(Debug)]
struct CompositeAdapter;

#[async_trait]
impl Adapter for CompositeAdapter {
    async fn tickets(&self, context: &CompletionContext) -> Result<Vec<Ticket>, AdapterError> {
        GithubAdapter.tickets(context).await
    }
}

#[derive(Debug, Default)]
pub struct InitializableAdapter {
    adapter: Arc<Mutex<Option<CompositeAdapter>>>,
}

impl InitializableAdapter {
    pub async fn initialize<'r>(&self, progress: &ProgressReporter<'r>) {
        progress.report(Some("Working..."), Some(25)).await;

        let mut mutex = self.adapter.lock().await;
        if mutex.is_none() {
            *mutex = Some(CompositeAdapter);
        }

        progress.report(Some("Done."), Some(100)).await;
    }
}

#[async_trait]
impl Adapter for InitializableAdapter {
    async fn tickets(&self, context: &CompletionContext) -> Result<Vec<Ticket>, AdapterError> {
        let mutex = self.adapter.lock().await;
        let adapter = mutex.as_ref().ok_or(AdapterError::NotInitialized)?;

        adapter.tickets(context).await
    }
}
