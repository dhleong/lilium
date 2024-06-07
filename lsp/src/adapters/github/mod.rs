mod cli;
mod model;

use async_trait::async_trait;

use crate::completion::CompletionContext;

use self::cli::GhCli;

use super::{Adapter, AdapterError, AdapterParams, Ticket};

#[derive(Debug)]
pub struct GithubAdapter {
    cli: GhCli,
}

impl GithubAdapter {
    pub async fn create(params: AdapterParams) -> Result<GithubAdapter, AdapterError> {
        let cli = GhCli { root: params.root };
        if !cli.is_authenticated().await? {
            Err(AdapterError::LoggedOut)
        } else {
            Ok(GithubAdapter { cli })
        }
    }
}

#[async_trait]
impl Adapter for GithubAdapter {
    async fn tickets(
        &self,
        context: &CompletionContext,
    ) -> Result<Vec<Ticket>, super::AdapterError> {
        let results = self.cli.tickets(&context.text).await?;
        let tickets = results
            .0
            .into_iter()
            .map(|result| Ticket {
                id: result.number.to_string(),
                reference: format!("#{id}", id = result.number),
                title: result.title,
                description: Some(result.body),
            })
            .collect();
        Ok(tickets)

        //     Ok(vec![
        //         Ticket {
        //             id: "9001".to_string(),
        //             reference: "#9001".to_string(),
        //             title: "Adjust emotional weights".to_string(),
        //             description: Some("Test github-like ticket".to_string()),
        //         },
        //         Ticket {
        //             id: "42".to_string(),
        //             reference: "https://asana.com/tickets/42".to_string(),
        //             title: "Reticulate Splines".to_string(),
        //             description: Some("Test asana-like ticket".to_string()),
        //         },
        //     ])
    }
}
