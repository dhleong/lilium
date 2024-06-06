use std::sync::Arc;

use async_trait::async_trait;
use tokio::sync::RwLock;
use tower_lsp::jsonrpc::{self, ErrorCode};

use crate::{completion::CompletionContext, progress::ProgressReporter};

use self::composite::CompositeAdapter;

mod composite;
mod github;

#[derive(Debug)]
pub struct Ticket {
    pub id: String,
    pub reference: String,
    pub title: String,
    pub description: Option<String>,
}

pub struct AdapterParams {
    pub root: Option<String>,
}

#[derive(Debug)]
pub enum AdapterError {
    NotInitialized,
    Unavailable,
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

#[derive(Debug, Default)]
pub struct InitializableAdapter {
    root: Arc<RwLock<Option<String>>>,
    adapter: Arc<RwLock<Option<CompositeAdapter>>>,
}

impl InitializableAdapter {
    pub async fn set_root(&self, root: String) {
        let mut mutex = self.root.write().await;
        *mutex = Some(root);
    }

    pub async fn initialize<'r>(&self, progress: &ProgressReporter<'r>) {
        progress.report(Some("Working..."), Some(25)).await;

        let mut mutex = self.adapter.write().await;
        let root = self.root.read().await;
        if mutex.is_none() {
            *mutex = Some(CompositeAdapter::create(AdapterParams { root: root.clone() }).await);
        }

        progress.report(Some("Ready!"), Some(100)).await;
    }
}

#[async_trait]
impl Adapter for InitializableAdapter {
    async fn tickets(&self, context: &CompletionContext) -> Result<Vec<Ticket>, AdapterError> {
        let mutex = self.adapter.read().await;
        let adapter = mutex.as_ref().ok_or(AdapterError::NotInitialized)?;

        adapter.tickets(context).await
    }
}
