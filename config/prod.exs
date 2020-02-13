use Mix.Config

config :mailgun_logger, MailgunLoggerWeb.Endpoint,
  http: [port: System.fetch_env!("PORT"), compress: true],
  url: [host: System.fetch_env!("HOST"), port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json",
  debug_errors: false,
  code_reloader: false,
  root: ".",
  version: Application.spec(:mailgun_logger, :vsn)

config :mailgun_logger,
  slack_hook: System.get_env("SLACK_HOOK")

config :phoenix, :serve_endpoints, true

config :logger, level: :info

# Quantum cron schedule
config :mailgun_logger, MailgunLogger.Scheduler,
  jobs: [
    {"0 7 * * *", {MailgunLogger, :run, []}},
    {"0 14 * * *", {MailgunLogger, :run, []}}
  ]
