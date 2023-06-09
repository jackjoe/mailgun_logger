defmodule MailgunLoggerWeb.Router do
  use MailgunLoggerWeb, :router
  use Plug.ErrorHandler
  @moduledoc false

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(Plug.Logger)
  end

  pipeline :ping do
    plug(:accepts, ["html"])
    plug(:put_secure_browser_headers)
  end

  pipeline :auth do
    plug(MailgunLoggerWeb.Plugs.SetupCheck)
    plug(MailgunLoggerWeb.Plugs.Auth)
  end

  # Always except in prod
  if Application.compile_env(:mailgun_logger, :env) == :dev do
    forward("/sent_emails", Bamboo.SentEmailViewerPlug)
  end

  scope "/ping", MailgunLoggerWeb do
    pipe_through([:ping])
    get("/", PingController, :ping)
  end

  scope "/health", MailgunLoggerWeb do
    pipe_through([:ping])
    get("/", PingController, :ping)
  end

  scope "/login", MailgunLoggerWeb do
    pipe_through(:browser)

    get("/", AuthController, :new)
    post("/", AuthController, :create)
  end

  scope "/password-reset", MailgunLoggerWeb do
    pipe_through(:browser)

    scope "/request" do
      get("/", PasswordResetController, :request_new)
      post("/", PasswordResetController, :request_create)
      get("/done", PasswordResetController, :request_done)
    end

    get("/reset/error", PasswordResetController, :reset_error)
    get("/reset/done", PasswordResetController, :reset_done)

    scope "/reset/:reset_token" do
      get("/", PasswordResetController, :reset_new)
      post("/", PasswordResetController, :reset_create)
    end
  end

  scope "/setup", MailgunLoggerWeb do
    pipe_through(:browser)
    get("/", SetupController, :index)
    post("/", SetupController, :create_root)
  end

  scope "/", MailgunLoggerWeb do
    pipe_through([:browser, :auth])

    get("/logout", AuthController, :logout)

    resources("/events", EventController, only: [:index, :show])
    get("/events/:id/stored_message", EventController, :stored_message)
    resources("/accounts", AccountController, except: [:show])
    resources("/users", UserController, except: [:show])

    get("/", PageController, :index)
    get("/stats", PageController, :stats)
    get("/graphs", PageController, :graphs)
    get("/non-affiliation", PageController, :non_affiliation)
    post("/trigger_run", PageController, :trigger_run)
  end
end
