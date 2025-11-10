CREATE TABLE IF NOT EXISTS projects (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT,
    created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS tenants (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT,
    created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS environments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS machines (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    roles TEXT NOT NULL,
    environment_ids TEXT NOT NULL,
    created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS releases (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id TEXT NOT NULL,
    version TEXT NOT NULL,
    notes TEXT,
    created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS deployments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    release_id TEXT NOT NULL,
    environment_id TEXT NOT NULL,
    status TEXT NOT NULL,
    started_at INTEGER NOT NULL,
    finished_at INTEGER
);

CREATE TABLE IF NOT EXISTS project_variables (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id TEXT NOT NULL,
    name TEXT NOT NULL,
    default_value TEXT,
    created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS tenant_variable_values (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id TEXT NOT NULL,
    variable_id TEXT NOT NULL,
    tenant_id TEXT NOT NULL,
    value TEXT NOT NULL,
    created_at INTEGER NOT NULL
);

-- Indexes for performance & uniqueness
CREATE UNIQUE INDEX IF NOT EXISTS idx_project_variables_project_name ON project_variables(project_id, name);
CREATE INDEX IF NOT EXISTS idx_releases_project ON releases(project_id);
CREATE INDEX IF NOT EXISTS idx_deployments_release ON deployments(release_id);
CREATE INDEX IF NOT EXISTS idx_tenant_values_keys ON tenant_variable_values(project_id, variable_id, tenant_id);
CREATE INDEX IF NOT EXISTS idx_machines_name ON machines(name);

-- (Optional) Future: add foreign key constraints once referential integrity strategy finalized.
-- Example (disabled for now due to TEXT ids & existing code paths):
-- ALTER TABLE releases ADD CONSTRAINT fk_releases_project FOREIGN KEY(project_id) REFERENCES projects(id);

-- End of migration.
