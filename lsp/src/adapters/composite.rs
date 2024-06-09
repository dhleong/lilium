use async_trait::async_trait;
use tokio::task::JoinHandle;

use crate::completion::CompletionContext;

use super::{
    asana::AsanaAdapter, github::GithubAdapter, Adapter, AdapterError, AdapterParams, Ticket,
};

#[derive(Debug)]
pub struct CompositeAdapter {
    asana: Option<AsanaAdapter>,
    github: Option<GithubAdapter>,
}

impl CompositeAdapter {
    pub async fn create(params: AdapterParams) -> CompositeAdapter {
        let github_job = tokio::spawn(GithubAdapter::create(params.clone()));
        let asana_job = tokio::spawn(AsanaAdapter::create(params.clone()));

        CompositeAdapter {
            asana: unpack_job(asana_job).await,
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
        let from_github = if let Some(github) = &self.github {
            github.tickets(context).await
        } else {
            Ok(vec![])
        };

        // TODO: Do this in parallel; support indicating that something is "incomplete" so we can
        // return results early while waiting for a slow adapter, but allow
        // clients to pull the results from that adapter later

        let from_asana = if let Some(asana) = &self.asana {
            asana.tickets(context).await
        } else {
            Ok(vec![])
        };

        match (from_github, from_asana) {
            (Ok(mut github), Ok(asana)) => {
                github.extend(asana);
                Ok(github)
            }
            (Ok(github), _) => Ok(github),
            (_, Ok(asana)) => Ok(asana),
            (err, _) => err,
        }
    }
}
