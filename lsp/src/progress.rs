use tower_lsp::{
    lsp_types::{
        notification, NumberOrString, ProgressParams, ProgressParamsValue, WorkDoneProgress,
        WorkDoneProgressBegin, WorkDoneProgressEnd, WorkDoneProgressReport,
    },
    Client,
};

pub struct Progress {
    pub message: Option<String>,
    pub percentage: Option<u32>,
}

#[derive(Debug)]
pub struct ProgressReporter<'a> {
    token: String,
    client: &'a Client,
}

impl<'a> ProgressReporter<'a> {
    pub async fn start(
        client: &'a Client,
        token: impl Into<String>,
        title: impl Into<String>,
        initial_progress: Option<Progress>,
    ) -> ProgressReporter<'a> {
        let token: String = token.into();
        client
            .send_notification::<notification::Progress>(ProgressParams {
                token: NumberOrString::String(token.clone()),
                value: ProgressParamsValue::WorkDone(WorkDoneProgress::Begin(
                    WorkDoneProgressBegin {
                        title: title.into(),
                        cancellable: Some(false),
                        percentage: initial_progress.as_ref().and_then(|p| p.percentage),
                        message: initial_progress.and_then(|p| p.message),
                    },
                )),
            })
            .await;
        Self { token, client }
    }

    pub async fn report(&self, message: Option<impl Into<String>>, percentage: Option<u32>) {
        self.client
            .send_notification::<notification::Progress>(ProgressParams {
                token: NumberOrString::String(self.token.clone()),
                value: ProgressParamsValue::WorkDone(WorkDoneProgress::Report(
                    WorkDoneProgressReport {
                        cancellable: Some(false),
                        percentage,
                        message: message.map(|s| s.into()),
                    },
                )),
            })
            .await;
    }

    pub async fn end(self, message: Option<String>) {
        self.client
            .send_notification::<notification::Progress>(ProgressParams {
                token: NumberOrString::String(self.token),
                value: ProgressParamsValue::WorkDone(WorkDoneProgress::End(WorkDoneProgressEnd {
                    message,
                })),
            })
            .await;
    }
}
