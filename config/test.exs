import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mailgun_logger, MailgunLogger.Endpoint,
  http: [port: 4001],
  server: false

# Quantum cron schedule
config :mailgun_logger, MailgunLogger.Scheduler,
  jobs: [
    # Every hour
    # {"50 * * * *", {MailgunLogger, :run, []}}
  ]

config :logger, level: :warn
config :mailgun_logger, MailgunLogger.Repo, pool: Ecto.Adapters.SQL.Sandbox

config :mailgun_logger, MailgunLogger.Repo,
  username: System.get_env("ML_DB_USER") || "postgres",
  password: System.get_env("ML_DB_PASSWORD") || "secret",
  database: System.get_env("ML_DB_NAME") || "mailgun",
  hostname: System.get_env("ML_DB_HOST") || "localhost"
