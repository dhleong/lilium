use serde::Deserialize;

#[derive(Clone, Debug, Deserialize)]
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
    pub gid: String,
    pub name: String,
    pub notes: String,
}
