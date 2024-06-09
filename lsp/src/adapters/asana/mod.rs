use std::{path::PathBuf, str::FromStr};

use async_trait::async_trait;
use tokio::fs;

use crate::fs::locate_file_in_parents;

use self::{api::AsanaClient, model::AsanaConfig};

use super::{Adapter, AdapterError, AdapterParams, Ticket};

const TASK_URL_BASE: &str = "https://app.asana.com/0/0";

mod api;
mod model;

#[derive(Debug)]
pub struct AsanaAdapter {
    config: AsanaConfig,
    client: AsanaClient,
}

impl AsanaAdapter {
    pub async fn create(params: AdapterParams) -> Result<AsanaAdapter, AdapterError> {
        let path = PathBuf::from_str(&params.root.ok_or(AdapterError::Unavailable)?)
            .map_err(|_| AdapterError::Unavailable)?;
        if let Some(config_path) = locate_file_in_parents(&path, ".lilium.asana.json").await {
            let config_bytes = fs::read(config_path).await?;
            let config = serde_json::from_slice(&config_bytes)?;
            return Ok(AsanaAdapter {
                config,
                client: AsanaClient::new(),
            });
        }

        // TODO: Env vars?
        Err(AdapterError::LoggedOut)
    }
}

#[async_trait]
impl Adapter for AsanaAdapter {
    async fn tickets(
        &self,
        context: &crate::completion::CompletionContext,
    ) -> Result<Vec<super::Ticket>, AdapterError> {
        let result = self
            .client
            .get_tasks(
                &self.config.token,
                self.config.workspace.as_ref(),
                &context.text,
            )
            .await?;
        Ok(result
            .data
            .into_iter()
            .map(|task| {
                let gid = &task.gid;
                let reference = format!("{TASK_URL_BASE}/{gid}");
                Ticket {
                    description: Some(reference.clone()),
                    // NOTE: The ID isn't super useful...
                    provider_prefix: "[ASANA]".to_string(),
                    id: task.gid,
                    title: task.name,
                    reference,
                }
            })
            .collect())
    }
}
