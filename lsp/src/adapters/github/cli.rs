use std::{ffi::OsStr, io, process::Output};

use tokio::process::Command;

use crate::adapters::AdapterError;

use super::model::GithubIssuesSearchResults;

#[derive(Debug)]
pub struct GhCli {
    pub root: Option<String>,
}

impl GhCli {
    pub async fn is_authenticated(&self) -> Result<bool, AdapterError> {
        let auth_result = self
            .execute(&["auth", "status"])
            .await
            .map_err(|_| AdapterError::Unavailable)?;
        Ok(auth_result.status.success())
    }

    pub async fn tickets(&self, query: &str) -> Result<GithubIssuesSearchResults, AdapterError> {
        let repo = if let Some(_) = &self.root {
            // TODO:
            Some("dhleong/wish")
        } else {
            None
        };

        let mut args = vec![
            "search",
            "issues",
            "--include-prs",
            "--state=open",
            "--json=number,title,repository,body",
        ];
        if let Some(repo) = repo {
            args.append(&mut vec!["--repo", repo, "--author", "@me"]);
        } else {
            args.append(&mut vec!["--assignee", "@me"]);
        }

        if !query.is_empty() {
            args.push(query);
        }

        let output = self.execute(args).await?;
        if !output.status.success() {
            return if let Ok(error) = String::from_utf8(output.stderr) {
                Err(AdapterError::Other(error))
            } else {
                Err(AdapterError::Other("Unexpected error".to_string()))
            };
        }

        Ok(serde_json::from_slice(&output.stdout)?)
    }

    pub async fn execute<I, S>(&self, args: I) -> io::Result<Output>
    where
        I: IntoIterator<Item = S>,
        S: AsRef<OsStr>,
    {
        let mut command = Command::new("gh");

        if let Some(root) = self.root.as_ref() {
            command.current_dir(root);
        }

        command.args(args).output().await
    }
}
