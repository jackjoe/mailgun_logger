defmodule MailgunLoggerWeb.Endpoint do
  @moduledoc false

  @session_options [store: :cookie, key: "_mailgun_logger_key", signing_salt: "xI0ktzaL"]

  use Phoenix.Endpoint, otp_app: :mailgun_logger

  socket("/socket", MailgunLoggerWeb.UserSocket)

  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug(
    Plug.Static,
    from: :mailgun_logger,
    at: "/",
    gzip: false,
    only: MailgunLoggerWeb.static_paths()
  )

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
    plug(Phoenix.LiveReloader)
    plug(Phoenix.CodeReloader)
  end

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug(Plug.Session, @session_options)
  plug(MailgunLoggerWeb.Router)

  def build_conn(), do: %Plug.Conn{private: %{phoenix_endpoint: MailgunLoggerWeb.Endpoint}}
end
