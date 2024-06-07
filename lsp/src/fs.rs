use std::path::{Path, PathBuf};

use tokio::fs;

pub async fn locate_file_in_parents(path: &Path, filename: &str) -> Option<PathBuf> {
    let start = fs::canonicalize(path).await.unwrap();
    let mut path: &Path = &start;
    while path.is_dir() {
        let candidate = path.join(filename);
        if fs::try_exists(&candidate).await.unwrap_or(false) {
            return Some(candidate);
        }
        path = path.parent()?;
    }

    None
}

#[cfg(test)]
mod tests {
    use std::str::FromStr;

    use super::*;

    #[tokio::test]
    async fn test_locate_file_in_parents() {
        // This is miserably hacky...
        let path = PathBuf::from_str(&format!("../{}", file!()))
            .unwrap()
            .parent()
            .unwrap()
            .to_path_buf();
        assert!(locate_file_in_parents(&path, "Cargo.toml").await.is_some());
    }
}
