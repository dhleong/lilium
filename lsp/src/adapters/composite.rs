use async_trait::async_trait;
use tokio::task::JoinHandle;

use crate::completion::CompletionContext;

use super::{
    asana::AsanaAdapter, cached::CachedAdapter, github::GithubAdapter, Adapter, AdapterError,
    AdapterParams, Ticket,
};

#[derive(Debug)]
pub struct CompositeAdapter {
    asana: Option<CachedAdapter<AsanaAdapter>>,
    github: Option<CachedAdapter<GithubAdapter>>,
}

impl CompositeAdapter {
    pub async fn create(params: AdapterParams) -> CompositeAdapter {
        let github_job = tokio::spawn(GithubAdapter::create(params.clone()));
        let asana_job = tokio::spawn(AsanaAdapter::create(params.clone()));

        let asana = CachedAdapter::wrap_and_init(unpack_job(asana_job).await);
        let github = CachedAdapter::wrap_and_init(unpack_job(github_job).await);

        CompositeAdapter { asana, github }
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

impl CompositeAdapter {
    pub async fn describe(&self) -> String {
        let mut output = String::default();

        output.push_str("## Github\n");
        if let Some(github) = &self.github {
            let cached_count = github.cached_count().await;
            let github = github.inner();
            output.push_str(&format!("Repo name: {:?}", github.repo_name));

            output.push_str(&format!("\nCached Tickets: {:?}", cached_count));
        } else {
            output.push_str("Not available.");
        }

        output.push_str("\n\n## Asana\n");
        if let Some(asana) = &self.asana {
            let cached_count = asana.cached_count().await;
            // TODO: auth?
            output.push_str("Configured!");
            output.push_str(&format!("\nCached Tickets: {:?}", cached_count));
        } else {
            output.push_str("Not available.");
        }

        return output;
    }
}
