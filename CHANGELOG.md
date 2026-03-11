## 2603.2.0 (2026-03-11)

**BREAKING**

This is a major infrastructure upgrade. Please review the breaking changes below before upgrading.

### Added

- Dark/light/system theme support with user preference stored in database
- Theme picker in user edit form (system/light/dark)
- Inline JS in layout for instant theme application (no flash-of-wrong-theme)
- System theme option respects `prefers-color-scheme` media query and reacts to OS changes

### Security

- Use distinct `signing_salt` for LiveView (was identical to `secret_key_base`)
- Add `SECRET_KEY_BASE` env var override in `releases.exs`
- Remove `check_origin: false` from base config (keep in `dev.exs` only)
- Disable `debug_errors` in production config
- Remove API key from Mailgun client URLs (was logged in plaintext via `Logger.debug`)
- Guard S3 uploads with `store_messages` config check; replace `ExAws.request!` with error-handling `ExAws.request`
- Use `String.to_existing_atom/1` for log level env var (prevents atom table exhaustion)

### Changed

- Complete UI overhaul: industrial/utilitarian dark theme with monospace typography throughout
- Replaced inline styles in templates with semantic CSS classes
- Login page: centered card layout
- Tables: dense rows, uppercase mono headers, no rounded corners
- Navigation: sticky header, amber accent underline for active state
- Alerts: left-border accent style (amber for warnings, red for errors, green for info)
- Forms: dark inset inputs with amber focus borders
- All CSS via custom properties for easy theming
- Removed obsolete `X-UA-Compatible` meta tag and empty `description` meta tag
- Fixed `target="blank"` to `target="_blank"` in event links
- Removed stale hard-coded subnav breadcrumb from layout
- All templates converted from `.eex` to `.heex` (HEEx)
- Layout partials (head/foot) inlined into layout templates
- `~L` sigils (LEEx) replaced with `~H` (HEEx) throughout
- `link/2` helpers replaced with `<.link>` components
- `form_for` replaced with `<.form>` components
- `phx-feedback-for` and `phx-no-feedback` removed from core components (removed in LiveView 1.0)
- `Flop.Phoenix.cursor_pagination` replaced with `Flop.Phoenix.pagination`
- Added `compilers: [:phoenix_live_view]` and `listeners: [Phoenix.CodeReloader]` to mix.exs (Phoenix 1.8 requirement)
- Endpoint: `gzip: false` -> `gzip: not code_reloading?`
- Config: `config :logger, :console` -> `config :logger, :default_formatter`
- Config: `import_config "#{Mix.env()}.exs"` -> `"#{config_env()}.exs"`
- Fixed test config referencing `MailgunLogger.Endpoint` instead of `MailgunLoggerWeb.Endpoint`
- Fixed core_components referencing wrong Gettext module
- Added `lazy_html` test dependency (LiveView 1.1 requirement)
- Dev config: added `phoenix_live_view` debug annotations and expensive runtime checks

### Performance

- Add time filter to `get_stats/1` query (was scanning entire events table)
- Use `Repo.aggregate` for account count instead of loading all rows

### Removed

- Dead modules: `Pager`, `Pager.Page`, `RunTriggererLive`, `UserSocket`, `PagingHelpers`
- Unused functions: `Users.assign_role/2`, `Emails.test_mail/1`, duplicate `Events.bucket/0`
- Unused socket mount from endpoint
- Unused `ml_pagesize` config
- Dead Papertrail config from `releases.exs`
- Stale `config :phoenix, :serve_endpoints` from prod config
- Stale `root: "."` from prod endpoint config
- Duplicate `config :logger` block in `config.exs`
- Removed `:phoenix_live_view` from compilers (obsolete since LiveView 0.18)
- Removed `import Phoenix.LiveView.Helpers` (removed in LiveView 1.0)

### Fixed

- `IO.inspect(changeset)` left in user controller error path
- `event["delivery-status"]["attempt-no"]` crash on non-delivery events (use `get_in/2`)

### Breaking changes

- **Removed `logger_papertrail_backend`** dependency and all Papertrail logging configuration. If you relied on Papertrail for log forwarding, you will need to set up an alternative solution.
- **Removed `:backends` logger configuration**. Elixir 1.19 / OTP 28 deprecates the `:backends` key. Logger now uses the default Erlang handler.
- **`Argon2.check_pass/2`** replaced with `Argon2.verify_pass/2` — no user-facing impact, but custom auth code referencing the old API will need updating.

### Upgraded

- **Phoenix 1.7 -> 1.8.5**
- **Phoenix LiveView 0.20 -> 1.1.27**
- **Ecto SQL 3.11 -> 3.13**, Postgrex 0.20 -> 0.22
- **Flop 0.25 -> 0.26**, Flop Phoenix 0.22 -> 0.25
- **Gettext 0.16 -> 0.25** (now uses `Gettext.Backend`)
- Plug 1.7 -> 1.19, Plug Cowboy 2.1 -> 2.8
- Elixir requirement: ~> 1.17, tested on Elixir 1.19.5 / OTP 28

## 2410.1.0 (2024-10-09)

- Fix: prevent creation of admins when setup has been done

Thanks to @DriesCruyskens !

## 2402.6.0 (2024-06-24)

- Feat: `store_messages` config var can now be set with an env var
- Fix: old mysql port is pg now
- Fix: typo

## 2402.2.0 (2024-02-27)

- Default ':delivered' filter

## 2402.1.0 (2024-02-27)

- Bump packages
- Fix `Endpoint.init/2` deprecation warning

## 2312.5.0 (2023-12-27)

- Bump packages
- Fix unhandled nil value in message content type check (#33)
- Enlarge `message_id` field (#32)

## 2312.4.0 (2023-12-20)

- Trim values for filters in search form

## 2312.3.0 (2023-12-12)

- Handle plain text raw messages

## 2312.2.0 (2023-12-07)

- Changed the trigger button from LV to POST (@m1dnight)

## 23012.1.0 (2023-12-06)

- Added index to inserted_at on events to speed things up (@m1dnight)

## 2309.1.0 (2023-09-26)

- Update some dependencies
- Update 'Readme'

## 2308.1.1 (2023-08-15)

- Add `check_origin` option

## 2308.1.0 (2023-08-15)

- Add event type filter to search form
- Bump packages

## 2307.1.1 (2023-07-06)

- Fix annoying error with the conn not being halted correctly

## 2307.1.0 (2023-07-06)

- Added LiveView component to trigger a new run

## 2305.7.0 (2023-06-30)

- Drastically improve query speed by removing a join

## 2305.6.2 (2023-06-30)

- Bump dependencies

## 2305.6.1 (2023-06-15)

- Ignore bgcolor attr in original event html

## 2305.6.0 (2023-06-09)

- Improve redirects
- Promote event listing to new home page (for faster loading)

## 2305.5.0 (2023-06-09)

- Add logger to Papertrail

## 2305.4.1 (2023-05-24)

- Provide env config option for the db port

## 2305.4.0 (2023-05-08)

- Cursor based pagination using Flop

## 2305.3.0 (2023-05-08)

- Add attachment info on the event detail page

## 2305.2.0 (2023-05-08)

- Update packages

## 2305.1.0 (2023-05-02)

**BREAKING**

In this release, we are no longer saving the actual stored message (the raw data) as it has proven to be too much stress on the db without any added value. There is a config option `store_messages` that, if set to `true` also requires an AWS config to be added. Then the raw messages will be stored in an S3 bucket.
Also, the `stored_message` data column should be regarded as deprecated and will be removed via a migration in a future release.

- Add AWS config and option to store the raw message there.

## 2302.1.1 (2023-02-27)

- Port `DATE_FORMAT` to PostgreSQL

## 2302.1.0 (2023-02-17)

- Migrate from MySQL to PostgreSQL

## 2209.4.0 (2022-09-12)

- Update event detail page to extract possible error message better
- Add stats and graphs to the dashboard

## 2209.3.0 (2022-09-08)

- Basic user management

## 2209.2.1 (2022-09-08)

- HOTFIX: uncomment important code (from testing)

## 2209.2.0 (2022-09-08)

- Fix password reset flow
- Update readme with Mailgun API key info
- Add send/recv output column to indicate if a message was received via an inbound route or a regular outgoing send

## 2209.1.0 (2022-09-07)

- Load internal Mailgun API key from runtime config

## 2202.4.4 (2022-07-21)

- Fix index length on events
- Fix unhandled error when using an invalid api key
- Release new version on our national holiday! 🇧🇪

## 2202.4.2 (2022-07-18)

- Increase `message_to` field size

## 2202.4.1

- Fix stored message slow query

## 2202.4.0

- Fix version numbering
- Fix old layout code in the setup template

## 2022.2.0

- Add account filter to the search

## 2021.9.3

- Improve detail page styling
- Optimize events query

## 0.3.0 (2021-07-20)

- Tweak styling
- Store actual sent messages and provide preview in the UI

## 0.2.0 (2021-05-15)

- Password reset flow

## 0.1.2 (2021-04-14)

- Upgrade to Phoenix 1.5.
- Output error type in red and delivered mails in green.

## 0.1.1 (2021-02-16)

- Fix database connection timeout when inserting a large amount of events with `Repo.transaction`, bu adding a infinit timeout to it.

## 0.1.0 (2021-02-03)

**POSSIBLY BREAKING! (Possibly, but not surely, so no 1.0.0 yet!)**

We had to alter the unique index (stupid mistake... more tests, anyone ;) ?). We do have a migration but it could be possible you have to alter that index yourself. It should be fairly easy, just add a unique constraint on the `accounts` table for columsn `api_key` and `domain`.

- fixed unique constraint for API key and domain on accounts. ([#7][i7])

## 0.0.5 (2020-10-14)

- removed Timex dependency

## 0.0.3 (2020-02-08)

We are on Github!

### Added

- Setup flow

[i7]: https://github.com/jackjoe/mailgun_logger/issues/7
