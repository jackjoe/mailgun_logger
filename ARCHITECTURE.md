## Mailgun Logger – Architecture Overview

This document gives a high‑level overview of how the Mailgun Logger codebase is structured and how HTTP requests flow through it. It is written for developers who are **new to Elixir and Phoenix** but familiar with typical MVC / web application concepts.

---

## Big picture

- **Goal**: Periodically pull email event data from Mailgun and store it in PostgreSQL, then provide a small web UI to browse/search those events and some basic statistics.
- **Tech stack**:
  - Elixir / OTP application
  - Phoenix 1.8 for the web layer (router, controllers, views/templates, components)
  - Ecto for database access (PostgreSQL)
  - Quantum scheduler for background jobs (in non‑dev/test environments)
  - ExAws for optional raw message storage in S3

At runtime, the application is an **OTP supervision tree**:

- `MailgunLogger.Application` (top‑level OTP application)
  - `MailgunLogger.Repo` – database connection pool
  - `MailgunLoggerWeb.Endpoint` – HTTP server entrypoint (Plug/Cowboy)
  - `MailgunLogger.Scheduler` – background scheduler (only in non‑dev/test)

---

## Project layout

- `lib/mailgun_logger/…` – **domain / business logic** (contexts, schemas, scheduler, mailer).
- `lib/mailgun_logger_web/…` – **web interface** (endpoint, router, plugs, controllers, views, templates, UI components).
- `priv/repo/…` – database migrations and seeds.
- `priv/static/…` – compiled frontend assets (JS/CSS/images).
- `config/*.exs` – environment‑specific configuration (HTTP port, HTTPS certs, DB connection, etc.).

You can think of `lib/mailgun_logger` as “model & services” and `lib/mailgun_logger_web` as “MVC web layer” in more traditional terms.

---

## Startup & supervision

### `MailgunLogger.Application`

- Defined in `lib/mailgun_logger/application.ex`.
- Implements `start/2`, which:
  - Optionally validates configuration for S3 raw message storage.
  - Starts a supervision tree with:
    - `MailgunLogger.PubSub` – Phoenix PubSub instance.
    - `MailgunLogger.Repo` – Ecto repo for Postgres.
    - `MailgunLoggerWeb.Endpoint` – HTTP endpoint.
    - `MailgunLogger.Scheduler` – **only** when `:env` is not `:dev` or `:test`.
- Implements `config_change/3` so the endpoint can be reconfigured on upgrades.

### `MailgunLogger.Repo`

- Standard Ecto repo module (see `lib/mailgun_logger/repo.ex`).
- Handles DB connections, queries, and transactions for all contexts.

---

## Web entrypoint: Endpoint, Router, Plugs

### Endpoint – `MailgunLoggerWeb.Endpoint`

Location: `lib/mailgun_logger_web/endpoint.ex`

- This is the **top‑level HTTP interface**:
  - Starts the WebSocket endpoint for LiveView at `/live`.
  - Serves static assets from `priv/static` at `/`.
  - In dev, enables live code reloading.
  - Sets up standard plugs:
    - `Plug.Parsers` for URL‑encoded, multipart, and JSON request bodies.
    - `Plug.MethodOverride` / `Plug.Head`.
    - `Plug.Session` for signed cookie sessions.
  - Finally **delegates all remaining requests** to `MailgunLoggerWeb.Router`:

    ```elixir
    plug(MailgunLoggerWeb.Router)
    ```

You can think of the endpoint as “Express + middleware setup” in Node terms.

### Router – `MailgunLoggerWeb.Router`

Location: `lib/mailgun_logger_web/router.ex`

- Declares **pipelines** and **routes**.
- Pipelines are reusable chains of plugs (middleware) applied to groups of routes.

#### Pipelines

- `:browser`
  - Accept `html`.
  - Fetch session and LiveView flash.
  - Set the default layout (`MailgunLoggerWeb.LayoutView, :app`).
  - CSRF protection and secure browser headers.
  - `Plug.Logger` for request logging.
- `:ping`
  - Minimal pipeline for health checks:
    - Accept `html`.
    - Secure browser headers.
- `:auth`
  - `MailgunLoggerWeb.Plugs.SetupCheck` – ensures the app has been initially configured (root user/account).
  - `MailgunLoggerWeb.Plugs.Auth` – enforces authentication and loads current user.
- `:redirect_member`
  - `MailgunLoggerWeb.Plugs.RedirectMember` – redirects non‑admin users away from admin‑only routes.

#### Routes / scopes (high level)

- `/ping` and `/health`
  - Pipelines: `:ping`
  - Controller: `PingController.ping/2`
  - Used for uptime/health checks.

- `/login`
  - Pipeline: `:browser`
  - `AuthController`:
    - `new` – login form.
    - `create` – authenticate and start a session.

- `/password-reset/...`
  - Pipeline: `:browser`
  - `PasswordResetController`:
    - Request a reset email, show success/error pages, handle reset token flows.

- `/setup`
  - Pipeline: `:browser`
  - `SetupController`:
    - Initial installation flow to create the first/root account and user.

- Authenticated user scope (`/`)
  - Pipelines: `:browser`, `:auth`
  - `AuthController.logout/2`
  - `EventController` – listing and viewing events, viewing stored raw message HTML.
  - `ProfileController` – edit/update the current user’s profile.
  - `PageController` – dashboard, trigger a manual fetch run, graphs, non‑affiliation page.

- Admin scope (`/` with extra plug)
  - Pipelines: `:browser`, `:auth`, `:redirect_member`
  - `UserController` – manage users (CRUD minus `show`).
  - `AccountController` – manage Mailgun accounts/configurations.
  - `PageController.stats/2` – higher‑level stats page.

**Router summary**: It maps URL paths to controller actions and decides which authentication/authorization plugs run before a given controller.

### Plugs

Location: `lib/mailgun_logger_web/plugs/*.ex`

- **`SetupCheck`**
  - Runs on authenticated routes.
  - Checks if initial setup (root user/account) is complete.
  - If not, redirects the user to the `/setup` flow.

- **`Auth`**
  - Handles authentication:
    - Looks at session/cookies.
    - Redirects to `/login` if the user is not authenticated.
  - Typically assigns `current_user` into the connection for controllers/views.

- **`RedirectMember`**
  - Authorization plug for admin‑only routes.
  - If the current user is only a “member” (no admin/superuser role), they are redirected away from admin sections.

Plugs are conceptually similar to middleware in other web frameworks: they receive the request/response and can transform or short‑circuit it.

---

## Controllers, views and templates

Phoenix uses **controllers + views + templates** in a pattern that should feel familiar to MVC developers:

- **Controller**: orchestrates a request: fetches data from contexts, decides which template to render or where to redirect.
- **View**: presentation helpers / rendering logic for a given resource/domain.
- **Template (`.heex`)**: HTML with embedded Elixir (server‑rendered).

### Key controllers

All controllers live under `lib/mailgun_logger_web/controllers/`.

- **`PageController`**
  - General pages:
    - Dashboard / index.
    - Triggering a manual Mailgun fetch run.
    - Graphs/statistics view.
    - Non‑affiliation info page.

- **`EventController`**
  - Works with the `MailgunLogger.Events` context.
  - Actions:
    - `index` – list events with filters and pagination via Flop.
      - Loads all accounts via `Accounts.list_accounts/0`.
      - Calls `Events.search_events/2` and passes results + metadata to the `:index` template.
    - `show` – show a single event, preloading its associated account.
    - `stored_message` – if an event has a stored raw message (in S3), fetch and display it as HTML in a stripped‑down layout.

- **`AccountController`**
  - Manages Mailgun accounts/config (domain, API key, etc.).
  - Uses the `MailgunLogger.Accounts` context.

- **`UserController`**
  - Admin‑side user management (create/edit/delete users).
  - Uses the `MailgunLogger.Users` context.

- **`ProfileController`**
  - Lets the **current authenticated user** edit their own profile.

- **`AuthController`**
  - Session management / login/logout.

- **`PasswordResetController`**
  - Handles password reset request and token‑based reset flows.
  - Uses email sending (via `MailgunLogger.Mailer` / Bamboo) for reset emails.

- **`SetupController`**
  - First‑time setup for the app: create initial root user and account.

- **`PingController`**
  - Simple health check endpoint used for `/ping` and `/health`.

### Views and templates

- Views live in `lib/mailgun_logger_web/views/*_view.ex`.
- Templates live in `lib/mailgun_logger_web/templates/**.html.heex`.
- Layouts:
  - `LayoutView` and templates under `templates/layout/` (e.g. `app.html.heex`, `setup.html.heex`).
  - The router’s `:browser` pipeline wires `app.html.heex` as default layout.

For example, the events UI is composed of:

- Controller: `MailgunLoggerWeb.EventController`
- View: `MailgunLoggerWeb.EventView`
- Templates: `templates/event/index.html.heex`, `templates/event/show.html.heex`, `templates/event/stored_message.html.heex`

### Components and helpers

- `lib/mailgun_logger_web/components/core_components.ex`
  - Reusable UI components (buttons, forms, tables, etc.), written for Phoenix 1.8.
- `lib/mailgun_logger_web/components/flop.ex`
  - Components/helpers for pagination and filtering using Flop.
- `lib/mailgun_logger_web/helpers/view_helpers.ex`
  - Miscellaneous presentation helpers used from templates.

---

## Domain / data layer (contexts & schemas)

The non‑web logic lives in `lib/mailgun_logger/` and is split into **contexts** (service‑style modules) and **schemas** (Ecto models).

### Schemas

Some important schemas (in `lib/mailgun_logger/**.ex`):

- `MailgunLogger.Event`
  - Represents a single Mailgun event (accepted, delivered, failed, clicked, opened, stored, …).
  - Stores metadata such as timestamp, recipient, subject, message ID, log level, and the raw event payload.

- `MailgunLogger.Account`
  - Represents a Mailgun account configuration (domain, API key, etc.).

- `MailgunLogger.User`
  - Represents an application user (email, password hash, roles, etc.).

- `MailgunLogger.Role` and `MailgunLogger.UserRole`
  - Basic role/permission modeling (admin, superuser, member).

### Contexts

Contexts encapsulate queries and domain logic; controllers call contexts rather than working with `Repo` directly.

- **`MailgunLogger.Events`**
  - Searching and listing events with filtering/pagination (via Flop).
  - Loading a single event and its “linked” events (sharing the same message ID).
  - Persisting raw events fetched from Mailgun (`save_events/2`):
    - Transforms raw JSON from Mailgun into schema attributes.
    - Uses `Ecto.Multi` to batch‑insert with `on_conflict: :nothing` to avoid duplicates.
  - Computing statistics over the last N hours (`get_stats/1`) for graphing.
  - Managing the `has_stored_message` flag when raw messages are stored externally.

- **`MailgunLogger.Accounts`**
  - Listing, creating, updating, and deleting accounts.

- **`MailgunLogger.Users`**
  - User CRUD and authentication‑related logic (password hashing via Argon2, etc.).

- **`MailgunLogger.Roles`**
  - Helpers around roles and authorizations.

- **`MailgunLogger.Emails`**
  - High‑level API for sending emails (e.g. password reset email content).

- **`MailgunLogger.Mailer`**
  - Bamboo mailer module used by `Emails` to actually send messages.

- **`MailgunLogger.Scheduler`**
  - Quantum scheduler module that defines periodic jobs:
    - Regularly calling the Mailgun API.
    - Using contexts to persist new events.

- **`MailgunLogger.Seeder`**
  - Helpers for database seeding (e.g. creating default roles/admin user).

---

## External integrations

- **Mailgun API**
  - Accessed via modules under `lib/mailgun/` (separate from `MailgunLogger.*` namespaces).
  - Responsible for:
    - Fetching events from the Mailgun Events API.
    - Optionally fetching raw message contents for stored messages.

- **PostgreSQL**
  - Used via `MailgunLogger.Repo` and Ecto schemas.
  - Migrations define tables and indexes (see `priv/repo/migrations`).

- **AWS S3 (optional)**
  - If `store_messages` is enabled and ExAws is configured:
    - Raw message bodies are stored in S3 rather than the DB.
    - The events table keeps metadata, and UI can load the stored raw message on demand.

---

## Request lifecycle (end‑to‑end)

Below is a simplified sequence for a typical authenticated web request, e.g. “view events list”:

1. **TCP/HTTP** request comes in on the configured port (dev: HTTPS on port 7070).
2. `MailgunLoggerWeb.Endpoint` receives it and runs global plugs:
   - Static asset check (for `/assets/...`).
   - Body parsing, method override, session handling, etc.
3. The request is **forwarded to `MailgunLoggerWeb.Router`**.
4. The router matches the path to a route, e.g. `GET /events`:
   - Applies the `:browser` and `:auth` pipelines:
     - Session & flash.
     - CSRF protection.
     - Loads current user (Auth plug).
   - Optional authorization via `:redirect_member` for admin‑only routes.
5. The matched controller action runs, e.g. `EventController.index/2`:
   - Calls the appropriate **context functions** (`Events.search_events/2`, `Accounts.list_accounts/0`).
   - Decides which template to render (or where to redirect).
6. The controller calls `render/3`:
   - Phoenix chooses the corresponding **view** (`EventView`) and **template** (`templates/event/index.html.heex`).
   - View helpers and components are used to build the final HTML.
7. The rendered HTML is sent back via the endpoint to the client.

Other flows (login, password reset, admin management) follow the same pattern but talk to different contexts and render different templates.

---

## How to explore further

If you are new to Elixir/Phoenix and want to understand more:

- Start with the **router**: `lib/mailgun_logger_web/router.ex`
  - This tells you which URLs exist and which controllers handle them.
- For any controller action, follow its call into a **context** in `lib/mailgun_logger/`.
- Look at the **view** and `.heex` template with the same name to see what gets rendered.
- Check `config/dev.exs` for how the dev server is configured (HTTPS certs, port 7070, etc.).

With that path (router → controller → context → view/template), you can usually trace any request or feature in this application.

