-- Схема analysis-api в analysis_db (файлы, задачи анализа).
\connect analysis_db

CREATE TABLE IF NOT EXISTS files (
    id           VARCHAR(36) PRIMARY KEY,
    project_id   VARCHAR(36) NOT NULL,
    filename     VARCHAR(255) NOT NULL,
    s3_path      TEXT NOT NULL,
    content_hash VARCHAR(64) NOT NULL DEFAULT '',
    size_bytes   BIGINT NOT NULL DEFAULT 0,
    created_at   TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_files_project_id ON files(project_id);
CREATE INDEX IF NOT EXISTS idx_files_dedup ON files(project_id, filename, content_hash);

CREATE TABLE IF NOT EXISTS analysis_tasks (
    id         VARCHAR(36) PRIMARY KEY,
    file_id    VARCHAR(36) NOT NULL REFERENCES files(id) ON DELETE CASCADE,
    status     VARCHAR(50) NOT NULL DEFAULT 'pending',
    type       VARCHAR(50) NOT NULL DEFAULT 'full_analysis',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tasks_file_id ON analysis_tasks(file_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON analysis_tasks(status);
