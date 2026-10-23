import Config

# This file runs at boot, also in a release. Read all values that
# come from the environment here, not in the compile-time config.

if config_env() != :test do
  config :mailgun_logger,
    store_messages: System.get_env("ML_STORE_MESSAGES", "false") |> String.downcase() == "true",
    page_size: String.to_integer(System.get_env("ML_PAGESIZE", "50"))

  config :mailgun_logger, MailgunLogger.Mailer,
    api_key: System.get_env("MAILGUN_API_KEY"),
    domain: System.get_env("MAILGUN_DOMAIN"),
    from: System.get_env("MAILGUN_FROM", "no-reply@jackjoe.be"),
    reply_to: System.get_env("MAILGUN_REPLY_TO", "no-reply@jackjoe.be")

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
end

if config_env() == :prod do
  config :mailgun_logger, MailgunLogger.Repo,
    username: System.fetch_env!("ML_DB_USER"),
    password: System.fetch_env!("ML_DB_PASSWORD"),
    database: System.fetch_env!("ML_DB_NAME"),
    hostname: System.fetch_env!("ML_DB_HOST"),
    port: String.to_integer(System.get_env("ML_DB_PORT", "5432"))

  config :mailgun_logger, MailgunLoggerWeb.Endpoint,
    server: true,
    http: [port: String.to_integer(System.get_env("PORT", "5050"))],
    url: [host: System.fetch_env!("HOST"), port: 80],
    secret_key_base: System.fetch_env!("SECRET_KEY_BASE")

  config :logger, level: String.to_existing_atom(System.get_env("ML_LOG_LEVEL", "info"))
end
