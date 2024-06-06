use async_trait::async_trait;
use tokio::task::JoinHandle;

use crate::completion::CompletionContext;

use super::{github::GithubAdapter, Adapter, AdapterError, AdapterParams, Ticket};

#[derive(Debug)]
pub struct CompositeAdapter {
    github: Option<GithubAdapter>,
}

impl CompositeAdapter {
    pub async fn create(params: AdapterParams) -> CompositeAdapter {
        let github_job = tokio::spawn(async { GithubAdapter::create(params).await });

        CompositeAdapter {
            github: unpack_job(github_job).await,
        }
    }
}

async fn unpack_job<T: Adapter>(job: JoinHandle<Result<T, AdapterError>>) -> Option<T> {
    job.await
        .ok()
        .unwrap_or(Err(AdapterError::Unavailable))
        .ok()
}

#[async_trait]
impl Adapter for CompositeAdapter {
    async fn tickets(&self, context: &CompletionContext) -> Result<Vec<Ticket>, AdapterError> {
        if let Some(github) = &self.github {
            github.tickets(context).await
        } else {
            Ok(vec![])
        }
    }
}
