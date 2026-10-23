import Config

config :mailgun_logger, MailgunLogger.Repo,
  username: System.get_env("ML_DB_USER", "postgres"),
  password: System.get_env("ML_DB_PASSWORD", "postgres"),
  database: System.get_env("ML_DB_NAME", "mailgun_logger_dev"),
  hostname: System.get_env("ML_DB_HOST", "localhost"),
  port: String.to_integer(System.get_env("ML_DB_PORT", "5432"))

port = String.to_integer(System.get_env("PORT", "7070"))

config :mailgun_logger, MailgunLoggerWeb.Endpoint,
  url: [
    host: System.get_env("HOST", "localhost"),
    scheme: "https",
    port: port
  ],
  https: [
    port: port,
    cipher_suite: :strong,
    keyfile: "priv/cert/selfsigned_key.pem",
    certfile: "priv/cert/selfsigned.pem"
  ],
  live_reload: [
    web_console_logger: true,
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/mailgun_logger_web/(?:controllers|components|lives|views|templates|router)/?.*\.(ex|heex)$}
    ]
  ],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]}
  ],
  secret_key_base: "xdqH3oUTBrhInZokQilYoQssKjar1v8WDa430ROaKGRwDvdUGQdYSs0A4NydiKfZ"

config :mailgun_logger, MailgunLogger.Scheduler, jobs: []

# Store sent emails in memory, see them at /sent_emails
config :mailgun_logger, MailgunLogger.Mailer, adapter: Swoosh.Adapters.Local
config :swoosh, :api_client, false

# Do not include metadata nor timestamps in development logs
config :logger, :default_formatter, format: "[$level] $message\n"
config :phoenix, :stacktrace_depth, 20

config :phoenix_live_view,
  debug_heex_annotations: true,
  enable_expensive_runtime_checks: true
