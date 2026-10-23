import Config

# The port, host and secrets come from the environment at boot,
# see config/runtime.exs. Bandit compresses responses by default.
config :mailgun_logger, MailgunLoggerWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  debug_errors: false,
  code_reloader: false,
  version: Application.spec(:mailgun_logger, :vsn)

config :logger, compile_time_purge_matching: [[application: :remote_ip]]

config :ex_aws, debug_requests: false

# Quantum cron schedule
config :mailgun_logger, MailgunLogger.Scheduler,
  jobs: [
    {"0 7 * * *", {MailgunLogger, :run, []}},
    {"0 14 * * *", {MailgunLogger, :run, []}}
  ]
