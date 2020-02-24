import Config

config :mailgun_logger, MailgunLogger.Repo,
  username: System.get_env("ML_DB_USER"),
  password: System.get_env("ML_DB_PASSWORD"),
  database: System.get_env("ML_DB_NAME"),
  hostname: System.get_env("ML_DB_HOST")
