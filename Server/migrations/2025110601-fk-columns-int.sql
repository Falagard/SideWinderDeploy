-- Migration: Convert foreign key TEXT columns to INTEGER and add FK constraints
-- Timestamp: 2025110601
-- Assumptions: Existing TEXT FK columns store numeric IDs only. No non-numeric data present.
-- NOTE: machines.environment_ids is a denormalized list of environment IDs (comma-separated?)
--       This migration leaves it as TEXT. A future migration can introduce a junction table
--       (machine_environments) for proper normalization.

BEGIN TRANSACTION;

-- releases.project_id TEXT -> INTEGER
CREATE TABLE releases_new (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id INTEGER NOT NULL,
    version TEXT NOT NULL,
    notes TEXT,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE ON UPDATE CASCADE
);
INSERT INTO releases_new (id, project_id, version, notes, created_at)
SELECT id, CAST(project_id AS INTEGER), version, notes, created_at FROM releases;
DROP TABLE releases;
ALTER TABLE releases_new RENAME TO releases;
CREATE INDEX IF NOT EXISTS idx_releases_project ON releases(project_id);

-- deployments.release_id / environment_id TEXT -> INTEGER
CREATE TABLE deployments_new (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    release_id INTEGER NOT NULL,
    environment_id INTEGER NOT NULL,
    status TEXT NOT NULL,
    started_at INTEGER NOT NULL,
    finished_at INTEGER,
    FOREIGN KEY (release_id) REFERENCES releases(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (environment_id) REFERENCES environments(id) ON DELETE CASCADE ON UPDATE CASCADE
);
INSERT INTO deployments_new (id, release_id, environment_id, status, started_at, finished_at)
SELECT id, CAST(release_id AS INTEGER), CAST(environment_id AS INTEGER), status, started_at, finished_at FROM deployments;
DROP TABLE deployments;
ALTER TABLE deployments_new RENAME TO deployments;
CREATE INDEX IF NOT EXISTS idx_deployments_release ON deployments(release_id);

-- project_variables.project_id TEXT -> INTEGER
CREATE TABLE project_variables_new (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    default_value TEXT,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE ON UPDATE CASCADE
);
INSERT INTO project_variables_new (id, project_id, name, default_value, created_at)
SELECT id, CAST(project_id AS INTEGER), name, default_value, created_at FROM project_variables;
DROP TABLE project_variables;
ALTER TABLE project_variables_new RENAME TO project_variables;
CREATE UNIQUE INDEX IF NOT EXISTS idx_project_variables_project_name ON project_variables(project_id, name);

-- tenant_variable_values: project_id, variable_id, tenant_id TEXT -> INTEGER
CREATE TABLE tenant_variable_values_new (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id INTEGER NOT NULL,
    variable_id INTEGER NOT NULL,
    tenant_id INTEGER NOT NULL,
    value TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (variable_id) REFERENCES project_variables(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE ON UPDATE CASCADE
);
INSERT INTO tenant_variable_values_new (id, project_id, variable_id, tenant_id, value, created_at)
SELECT id, CAST(project_id AS INTEGER), CAST(variable_id AS INTEGER), CAST(tenant_id AS INTEGER), value, created_at FROM tenant_variable_values;
DROP TABLE tenant_variable_values;
ALTER TABLE tenant_variable_values_new RENAME TO tenant_variable_values;
CREATE INDEX IF NOT EXISTS idx_tenant_values_keys ON tenant_variable_values(project_id, variable_id, tenant_id);

COMMIT;

-- Post-migration verification queries (optional):
-- SELECT typeof(project_id) FROM releases LIMIT 1;
-- PRAGMA foreign_key_check;

-- Future improvement:
--   Create machine_environments(machine_id INTEGER, environment_id INTEGER, PRIMARY KEY(machine_id, environment_id),
--     FOREIGN KEY(machine_id) REFERENCES machines(id), FOREIGN KEY(environment_id) REFERENCES environments(id));
--   Then drop machines.environment_ids and populate junction table.
