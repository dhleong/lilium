use async_trait::async_trait;

use crate::completion::CompletionContext;

use super::{Adapter, Ticket};

pub struct GithubAdapter;

#[async_trait]
impl Adapter for GithubAdapter {
    async fn tickets(
        &self,
        context: &CompletionContext,
    ) -> Result<Vec<Ticket>, super::AdapterError> {
        Ok(vec![
            Ticket {
                id: "9001".to_string(),
                reference: "#9001".to_string(),
                title: "Adjust emotional weights".to_string(),
                description: Some("Test github-like ticket".to_string()),
            },
            Ticket {
                id: "42".to_string(),
                reference: "https://asana.com/tickets/42".to_string(),
                title: "Reticulate Splines".to_string(),
                description: Some("Test asana-like ticket".to_string()),
            },
        ])
    }
}
