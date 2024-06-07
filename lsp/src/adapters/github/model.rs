use serde::Deserialize;

#[derive(Deserialize)]
pub struct GithubIssuesSearchResults(pub Vec<GithubIssuesSearchResult>);

#[derive(Deserialize)]
pub struct GithubIssuesSearchResult {
    pub number: u64,
    pub title: String,
    pub body: String,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct GithubNameWithOwner {
    pub name_with_owner: String,
}
