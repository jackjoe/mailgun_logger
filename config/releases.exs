import Config

config :mailgun_logger, MailgunLogger.Repo,
  username: System.get_env("ML_DB_USER"),
  password: System.get_env("ML_DB_PASSWORD"),
  database: System.get_env("ML_DB_NAME"),
  hostname: System.get_env("ML_DB_HOST")

config :mailgun_logger, MailgunLogger.Mailer,
  adapter: Bamboo.MailgunAdapter,
  api_key: System.get_env("MAILGUN_API_KEY"),
  domain: System.get_env("MAILGUN_DOMAIN"),
  from: System.get_env("MAILGUN_FROM") || "no-reply@jackjoe.be"
