use std::sync::Arc;

use async_trait::async_trait;
use itertools::Itertools;
use tokio::sync::RwLock;
use tower_lsp::lsp_types::Position;

use crate::completion::{CompletionContext, CompletionKind};

use super::{Adapter, Ticket};

#[derive(Clone, Debug)]
pub struct CachedAdapter<T: Adapter + Sync> {
    adapter: T,
    cached_tickets: Arc<RwLock<Option<Vec<Ticket>>>>,
}

impl<T: Adapter + Sync + Send + Clone + 'static> CachedAdapter<T> {
    pub fn wrap_and_init(adapter: Option<T>) -> Option<Self> {
        if let Some(wrapped) = Self::wrap(adapter) {
            let mut cloned = wrapped.clone();
            tokio::spawn(async move {
                cloned.init().await;
            });
            Some(wrapped)
        } else {
            None
        }
    }
}

impl<T: Adapter + Sync> CachedAdapter<T> {
    pub fn wrap(adapter: Option<T>) -> Option<Self> {
        adapter.map(Self::new)
    }

    pub fn new(adapter: T) -> Self {
        Self {
            adapter,
            cached_tickets: Arc::new(RwLock::new(None)),
        }
    }

    pub async fn init(&mut self) {
        let context = CompletionContext {
            kind: CompletionKind::Tickets,
            text: "".to_string(),
            prefix_start: Position {
                line: 0,
                character: 0,
            },
        };
        if let Ok(tickets) = self.adapter.tickets(&context).await {
            let mut mutex = self.cached_tickets.write().await;
            *mutex = Some(tickets);
        }
    }

    pub async fn cached_count(&self) -> Option<usize> {
        let mutex = self.cached_tickets.read().await;
        mutex.as_ref().map(|v| v.len())
    }

    pub fn inner(&self) -> &T {
        &self.adapter
    }
}

#[async_trait]
impl<T: Adapter + Sync> Adapter for CachedAdapter<T> {
    async fn tickets(
        &self,
        context: &CompletionContext,
    ) -> Result<Vec<Ticket>, super::AdapterError> {
        let base = self.cached_tickets.read().await.clone();
        if context.text.is_empty() {
            if let Some(base) = base {
                // Skip querying again; there's no search filter, and we already
                // have these results!
                return Ok(base.clone());
            }
        }

        match (base, self.adapter.tickets(context).await) {
            (Some(base), Ok(results)) => Ok([base, results]
                .concat()
                .into_iter()
                .unique_by(|ticket| ticket.reference.clone())
                .collect_vec()),
            (Some(base), Err(_)) => Ok(base),
            (None, fresh_result) => fresh_result,
        }
    }
}
