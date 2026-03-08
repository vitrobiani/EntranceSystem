use axum::Json;
use serde::Serialize;
use sqlx::SqlitePool;

#[derive(sqlx::FromRow, Serialize, Clone)]
pub struct AccessEvent {
    id: i64,
    uid: String,
    status: String,
    timestamp: String,
}

#[derive(Clone)]
pub struct Database(SqlitePool);

impl Database {
    pub async fn new(url: &str) -> Self {
        let pool = SqlitePool::connect(url)
            .await
            .expect("DB connection failed");
        Self::init(&pool).await;
        Self(pool)
    }

    async fn init(pool: &SqlitePool) {
        sqlx::query(
            "CREATE TABLE IF NOT EXISTS access_log (
                id        INTEGER PRIMARY KEY AUTOINCREMENT,
                uid       TEXT NOT NULL,
                status    TEXT NOT NULL,
                timestamp TEXT NOT NULL
            )",
        )
        .execute(pool)
        .await
        .expect("Failed initilizing table");
    }

    pub async fn insert_log(&self, uid: &str, status: &str) -> Result<(), sqlx::Error> {
        sqlx::query("INSERT INTO access_log (uid, status, timestamp) VALUES (?, ?, ?)")
            .bind(uid)
            .bind(status)
            .bind(chrono::Local::now().to_string())
            .execute(&self.0)
            .await?;
        Ok(())
    }

    pub async fn get_logs(&self) -> Json<Vec<AccessEvent>> {
        let events =
            sqlx::query_as::<_, AccessEvent>("SELECT * FROM access_log ORDER BY id DESC LIMIT 100")
                .fetch_all(&self.0)
                .await
                .unwrap();

        println!("Returning {} events", events.len());
        Json(events)
    }
}
