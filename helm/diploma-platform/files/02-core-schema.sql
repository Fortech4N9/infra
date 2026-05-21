-- Схема core_api в core_db на первом старте тома (до запуска приложений).
-- Каждый .sql в initdb.d подключается к БД по умолчанию (diplom), поэтому явный \connect.
\connect core_db

CREATE TABLE IF NOT EXISTS users (
    id         VARCHAR(36) PRIMARY KEY,
    email      VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role       VARCHAR(20) NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
    analysis_quota INTEGER NOT NULL DEFAULT 10 CHECK (analysis_quota >= 0),
    is_active  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS projects (
    id         VARCHAR(36) PRIMARY KEY,
    user_id    VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name       VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_projects_user_id ON projects(user_id);
