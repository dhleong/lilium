use std::{io, sync::Arc};

use async_trait::async_trait;
use tokio::sync::RwLock;
use tower_lsp::jsonrpc::{self, ErrorCode};

use crate::{completion::CompletionContext, progress::ProgressReporter};

use self::composite::CompositeAdapter;

mod asana;
mod cached;
pub(crate) mod composite;
mod github;

#[derive(Clone, Debug)]
pub struct Ticket {
    pub id: String,
    pub reference: String,
    pub title: String,
    pub provider_prefix: String,
    pub description: Option<String>,
}

#[derive(Clone)]
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
            code: ErrorCode::ServerError(500),
            message: format!("{value:?}").into(),
            data: None,
        }
    }
}

impl From<io::Error> for AdapterError {
    fn from(value: io::Error) -> Self {
        AdapterError::Other(value.to_string())
    }
}

impl From<serde_json::Error> for AdapterError {
    fn from(value: serde_json::Error) -> Self {
        AdapterError::Other(value.to_string())
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
        let mut mutex = self.adapter.write().await;
        if mutex.is_none() {
            progress.report(Some("Working..."), Some(0)).await;

            let root = self.root.read().await;

            *mutex = Some(CompositeAdapter::create(AdapterParams { root: root.clone() }).await);

            progress.report(Some("Ready!"), Some(100)).await;
        }
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
