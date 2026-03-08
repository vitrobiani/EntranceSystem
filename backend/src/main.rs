use axum::{
    extract::State,
    response::sse::{Event, Sse},
    routing::get,
    Json, Router,
};
use futures::stream::{self, Stream};
use std::convert::Infallible;
use std::sync::Arc;
use tokio::sync::Notify;
use tower_http::cors::CorsLayer;
mod db;
use db::{AccessEvent, Database};

mod hardware;
use hardware::read_loop;

#[derive(Clone)]
struct AppState {
    db: Database,
    notify: Arc<Notify>,
}

#[tokio::main]
async fn main() {
    let db = Database::new("sqlite://access.db").await;

    let notify = Arc::new(Notify::new());

    let state = AppState {
        db: db.clone(),
        notify: notify.clone(),
    };

    tokio::spawn(read_loop(db, notify));

    let cors_layer = CorsLayer::permissive();

    let app = Router::new()
        .route("/", get(get_logs))
        .route("/sse", get(sse_handler))
        .with_state(state)
        .layer(cors_layer);

    // run our app with hyper, listening globally on port 3000
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn get_logs(State(state): State<AppState>) -> Json<Vec<AccessEvent>> {
    state.db.get_logs().await
}

async fn sse_handler(
    State(state): State<AppState>,
) -> Sse<impl Stream<Item = Result<Event, Infallible>>> {
    let stream = stream::unfold(state.notify.clone(), |notify: Arc<Notify>| async move {
        notify.notified().await;

        let event = Event::default().data("activated!");
        Some((Ok::<_, Infallible>(event), notify))
    });

    Sse::new(stream).keep_alive(axum::response::sse::KeepAlive::default())
}
