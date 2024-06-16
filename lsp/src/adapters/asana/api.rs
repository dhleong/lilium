use reqwest::Client;

use crate::adapters::AdapterError;

use super::model::AsanaTasksResult;

const API_BASE: &str = "https://app.asana.com/api/1.0";

#[derive(Clone, Debug)]
pub struct AsanaClient {
    client: Client,
}

impl AsanaClient {
    pub fn new() -> Self {
        Self {
            client: reqwest::Client::new(),
        }
    }

    pub async fn get_tasks(
        &self,
        token: &str,
        workspace: Option<&String>,
        text: &str,
    ) -> Result<AsanaTasksResult, AdapterError> {
        if let Some(workspace) = workspace {
            let mut query_params = vec![("resource_type", "task"), ("opt_fields", "name,notes")];

            if !text.is_empty() {
                query_params.push(("query", text));
            }

            let response = self
                .client
                .get(format!("{API_BASE}/workspaces/{workspace}/typeahead"))
                .header("Authorization", format!("Bearer {token}"))
                .query(&query_params)
                .send()
                .await?;

            let is_success = response.status().is_success();
            let bytes = response.bytes().await?;

            if is_success {
                return Ok(serde_json::from_slice(&bytes)?);
            }

            return Err(AdapterError::Other(
                String::from_utf8_lossy(&bytes).to_string(),
            ));
        }

        Ok(AsanaTasksResult { data: vec![] })
    }
}

impl From<reqwest::Error> for AdapterError {
    fn from(value: reqwest::Error) -> Self {
        Self::Other(value.to_string())
    }
}
