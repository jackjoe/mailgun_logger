import Config

config :mailgun_logger, MailgunLoggerWeb.Endpoint,
  http: [port: 4001],
  server: false

config :mailgun_logger, MailgunLogger.Scheduler,
  jobs: []

config :logger, level: :warning

config :mailgun_logger, MailgunLogger.Repo,
  username: System.get_env("ML_DB_USER") || "max",
  password: System.get_env("ML_DB_PASSWORD") || "",
  database: System.get_env("ML_DB_NAME") || "mailgun_logger_test",
  hostname: System.get_env("ML_DB_HOST") || "localhost",
  port: String.to_integer(System.get_env("ML_DB_PORT") || "5432"),
  pool: Ecto.Adapters.SQL.Sandbox
