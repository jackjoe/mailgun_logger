import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mailgun_logger, MailgunLoggerWeb.Endpoint,
  http: [port: 4001],
  secret_key_base: "82U7cl5b10o+5Y4VbAbmWrWSE36+jhBCZfOuuVCQz+e9S7knLqJxSgGr061HnnKG",
  server: false

# Quantum cron schedule
config :mailgun_logger, MailgunLogger.Scheduler, jobs: []

config :mailgun_logger, MailgunLogger.Mailer, adapter: Swoosh.Adapters.Test

config :logger, level: :warning

# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
config :mailgun_logger, MailgunLogger.Repo,
  username: System.get_env("ML_DB_USER", "postgres"),
  password: System.get_env("ML_DB_PASSWORD", "postgres"),
  database: "mailgun_logger_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: System.get_env("ML_DB_HOST", "localhost"),
  port: String.to_integer(System.get_env("ML_DB_PORT", "5432")),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2
