CREATE DATABASE IF NOT EXISTS analysis_metrics;

CREATE TABLE IF NOT EXISTS analysis_metrics.static_patterns (
    task_id             String,
    project_id          String,
    sequence_index      UInt32,
    source_file         String,
    source_line         UInt32,
    source_column       UInt32,
    function            String,
    base_symbol         String,
    base_kind           String,
    access_kind         String,
    pattern_type        String,
    pattern_fingerprint String,
    affine              UInt8,
    stride              Nullable(Float64),
    depth               UInt8,
    has_indexed_addr    UInt8,
    indexed_by_memory   UInt8,
    conditional         UInt8,
    fill_factor         Float64,
    alignment           Nullable(UInt32),
    working_set_bytes   UInt64,
    dependence          String,
    pattern_signature   String,
    contiguous_block    Nullable(UInt32),
    load_count          UInt32,
    store_count         UInt32,
    cache_profile_hash  String,
    artifact_s3_path    String,
    created_at          DateTime DEFAULT now()
)
ENGINE = MergeTree()
ORDER BY (task_id, source_line, source_column, base_symbol, access_kind);

CREATE TABLE IF NOT EXISTS analysis_metrics.dynamic_pattern_metrics (
    task_id             String,
    sequence_index      UInt32,
    pattern_fingerprint String,
    base_symbol         String,
    access_kind         String,
    cache_profile_hash  String,
    cache_level         String,
    misses_total        UInt64,
    misses_read         UInt64,
    misses_write        UInt64,
    source_task_id      String,
    source_file         String,
    interpreter_version String,
    created_at          DateTime DEFAULT now()
)
ENGINE = MergeTree()
ORDER BY (task_id, sequence_index, pattern_fingerprint, base_symbol, access_kind, cache_profile_hash, cache_level, created_at);

CREATE TABLE IF NOT EXISTS analysis_metrics.variable_sequences (
    task_id                String,
    project_id             String,
    cache_profile_hash     String,
    base_symbol            String,
    variable_sequence_hash String,
    pattern_count          UInt32,
    created_at             DateTime DEFAULT now()
)
ENGINE = MergeTree()
ORDER BY (project_id, cache_profile_hash, base_symbol, variable_sequence_hash, task_id);
