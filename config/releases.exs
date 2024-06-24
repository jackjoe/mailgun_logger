import Config

config :mailgun_logger, MailgunLogger.Repo,
  username: System.get_env("ML_DB_USER"),
  password: System.get_env("ML_DB_PASSWORD"),
  database: System.get_env("ML_DB_NAME"),
  hostname: System.get_env("ML_DB_HOST"),
  port: System.get_env("ML_DB_PORT") || 5432

config :mailgun_logger, MailgunLogger.Mailer,
  adapter: Bamboo.MailgunAdapter,
  api_key: System.get_env("MAILGUN_API_KEY"),
  domain: System.get_env("MAILGUN_DOMAIN"),
  from: System.get_env("MAILGUN_FROM") || "no-reply@jackjoe.be"

config :logger, logger_papertrail_backend: [host: System.get_env("PAPERTRAIL_HOST")]

config :ex_aws,
  access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
  region: System.get_env("AWS_REGION"),
  bucket: System.get_env("AWS_BUCKET"),
  raw_path: System.get_env("RAW_PATH"),
  s3: [
    scheme: System.get_env("AWS_SCHEME"),
    port: System.get_env("AWS_PORT"),
    region: System.get_env("AWS_REGION"),
    host: System.get_env("AWS_HOST")
  ]
