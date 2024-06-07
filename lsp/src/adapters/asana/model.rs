use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct AsanaConfig {
    pub token: String,
    pub workspace: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct AsanaTasksResult {
    pub data: Vec<AsanaTask>,
    // TODO: Error response
}

#[derive(Debug, Deserialize)]
pub struct AsanaTask {
    pub name: String,
    pub gid: String,
}
