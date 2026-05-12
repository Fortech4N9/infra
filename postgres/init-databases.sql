-- Создаются при первом запуске пустого тома (docker-entrypoint-initdb.d).
-- Имена должны совпадать с CORE_DB_NAME и ANALYSIS_DB_NAME в .env
CREATE DATABASE core_db;
CREATE DATABASE analysis_db;
