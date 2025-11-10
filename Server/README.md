SideWinder Deploy Server (Octopus-Style API Prototype)
=====================================================

This project is a deployment automation style API (inspired by Octopus Deploy) built with SideWinder (DI, AutoRouter, Database), snake-server (HTTP), and Lime/HashLink (runtime). All core entities are now persisted in SQLite via the SideWinder `Database` layer. Routing is annotation-driven directly on service interfaces (controllers removed).

Current Feature Set
-------------------
* Projects, Environments, Machines, Releases, Deployments
* Tenants + per-project variables + per-tenant overrides
* Auto-increment release patch versioning
* Asynchronous deployment simulation (Queued → Executing → Succeeded)
* Full database persistence (schema in `migrations/2025110401-deploy-schema.sql`)

Data Models (Fields)
--------------------
Project { id, name, description, createdAt }
Environment { id, name, createdAt }
Machine { id, name, roles[], environmentIds[], createdAt }
Release { id, projectId, version, notes, createdAt }
Deployment { id, releaseId, environmentId, status, startedAt, finishedAt? }
Tenant { id, name, description, createdAt }
ProjectVariable { id, projectId, name, defaultValue, createdAt }
TenantProjectVariableValue { id, projectId, variableId, tenantId, value, createdAt }

Routing & Annotations
---------------------
Each service interface is annotated, e.g.:
`@get("/api/projects")` on `listProjects()` in `IProjectService`.
This removes the need for separate controllers. Update vs create operations currently use `POST` for both (could move updates to `PUT` later).

Unified API Endpoints
---------------------
Base path: `/api`

Projects:
* GET  /api/projects
* POST /api/projects  { name, description }
* GET  /api/projects/:id
* POST /api/projects/:id  { name?, description? }  (update)
* DELETE /api/projects/:id

Releases:
* POST /api/projects/:projectId/releases  { notes }
* GET  /api/projects/:projectId/releases
* GET  /api/releases/:id

Deployments:
* POST /api/releases/:releaseId/deployments  { environmentId }
* GET  /api/releases/:releaseId/deployments
* GET  /api/deployments/:id

Environments:
* GET  /api/environments
* POST /api/environments  { name }
* GET  /api/environments/:id

Machines:
* GET  /api/machines
* POST /api/machines  { name, roles[], environmentIds[] }
* GET  /api/machines/:id

Tenants:
* GET  /api/tenants
* POST /api/tenants { name, description }
* GET  /api/tenants/:id
* POST /api/tenants/:id { name?, description? } (update)
* DELETE /api/tenants/:id

Project Variables:
* GET  /api/projects/:projectId/variables
* POST /api/projects/:projectId/variables { name, defaultValue }
* GET  /api/variables/:id
* POST /api/variables/:id { name?, defaultValue? } (update)
* DELETE /api/variables/:id

Tenant Variable Overrides:
* POST /api/projects/:projectId/variables/:variableId/tenants/:tenantId/value { value }
* GET  /api/projects/:projectId/variables/:variableId/tenants/:tenantId/value
* GET  /api/projects/:projectId/tenants/:tenantId/variables
* DELETE /api/projects/:projectId/tenant-variable-values (all overrides for project)
* DELETE /api/project-variables/:variableId/tenant-variable-values (all overrides for variable)
* DELETE /api/tenants/:tenantId/tenant-variable-values (all overrides for tenant)

Standard Status Codes
---------------------
200 OK, 201 Created, 202 Accepted (deployment queued), 400 Bad Request, 404 Not Found.

Example JSON Bodies
-------------------
Create Project:
```json
{ "name": "WebApp", "description": "Initial" }
```
Update Project:
```json
{ "name": "WebApp-Renamed" }
```
Create Release:
```json
{ "notes": "Add login feature" }
```
Create Deployment:
```json
{ "environmentId": "1" }
```
Create Machine:
```json
{ "name": "web-01", "roles": ["web"], "environmentIds": ["1"] }
```
Create Project Variable:
```json
{ "name": "ConnectionString", "defaultValue": "Server=dev;DB=app" }
```
Set Tenant Variable Override:
```json
{ "projectId": "1", "variableId": "2", "tenantId": "3", "value": "Server=prod;DB=app" }
```

Database & Migrations
---------------------
Schema migration file: `migrations/2025110401-deploy-schema.sql` (id AUTOINCREMENT, timestamps stored as epoch milliseconds). Services also include `CREATE TABLE IF NOT EXISTS` calls; you can remove those once a migration runner is invoked before service initialization.

Release Versioning
------------------
Patch number auto-increments per project (`1.0.<n>`). The service queries existing releases to compute the next patch.

Deployment Simulation
---------------------
Deployments start as `Queued`, quickly transition to `Executing`, then `Succeeded` (demo only). Finished time stored when terminal status reached.

Tenant Overrides Resolution
---------------------------
If an override exists for `(projectId, variableId, tenantId)`, its value is returned; otherwise the variable's `defaultValue` applies.

Quick Test (PowerShell)
-----------------------
```powershell
Invoke-WebRequest http://127.0.0.1:8000/api/projects | Select-Object -ExpandProperty Content
Invoke-WebRequest http://127.0.0.1:8000/api/projects -Method POST -Body '{"name":"WebApp","description":"Initial"}' -ContentType application/json | Select-Object -ExpandProperty Content
Invoke-WebRequest http://127.0.0.1:8000/api/projects/1/releases -Method POST -Body '{"notes":"First release"}' -ContentType application/json | Select-Object -ExpandProperty Content
Invoke-WebRequest http://127.0.0.1:8000/api/releases/1/deployments -Method POST -Body '{"environmentId":"1"}' -ContentType application/json | Select-Object -ExpandProperty Content
```

Typical Lifecycle
-----------------
1. Create project & environments
2. (Optional) Register machines
3. Create release
4. Deploy release
5. Monitor deployment
6. Define project variables
7. Add tenants
8. Apply tenant overrides

Planned Improvements
--------------------
* Switch update endpoints from POST to PUT/PATCH
* Foreign key constraints and proper cascading in SQLite
* Health & metrics endpoints
* Validation layer & structured error responses
* Auth (API keys / JWT) & RBAC
* SSE/WebSocket deployment log streaming

Disclaimer
----------
Prototype / learning artifact – not production ready. Use as a scaffold for a richer deployment platform.

