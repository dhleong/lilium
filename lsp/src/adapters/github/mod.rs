mod cli;
mod model;

use async_trait::async_trait;

use crate::completion::CompletionContext;

use self::cli::GhCli;

use super::{Adapter, AdapterError, AdapterParams, Ticket};

#[derive(Debug)]
pub struct GithubAdapter {
    cli: GhCli,
    repo_name: Option<String>,
}

impl GithubAdapter {
    pub async fn create(params: AdapterParams) -> Result<GithubAdapter, AdapterError> {
        let cli = GhCli { root: params.root };
        if !cli.is_authenticated().await? {
            return Err(AdapterError::LoggedOut);
        }

        let repo_name = cli.repo_name().await.ok();
        Ok(GithubAdapter { cli, repo_name })
    }
}

#[async_trait]
impl Adapter for GithubAdapter {
    async fn tickets(
        &self,
        context: &CompletionContext,
    ) -> Result<Vec<Ticket>, super::AdapterError> {
        let results = self
            .cli
            .tickets(self.repo_name.as_deref(), &context.text)
            .await?;
        let tickets = results
            .0
            .into_iter()
            .map(|result| Ticket {
                id: result.number.to_string(),
                reference: format!("#{id}", id = result.number),
                title: result.title,
                provider_prefix: format!("[GH#{id}]", id = result.number),
                description: if result.body.is_empty() {
                    None
                } else {
                    Some(result.body)
                },
            })
            .collect();
        Ok(tickets)
    }
}
