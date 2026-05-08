defmodule MailgunLoggerWeb.Router do
  use MailgunLoggerWeb, :router
  use Plug.ErrorHandler
  @moduledoc false

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_layout, {MailgunLoggerWeb.LayoutView, :app})
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

  pipeline :can_view_events do
    plug(MailgunLoggerWeb.Plugs.Authorize, :view_events)
  end

  pipeline :can_view_event_details do
    plug(MailgunLoggerWeb.Plugs.Authorize, :view_event_details)
  end

  pipeline :can_edit_own_profile do
    plug(MailgunLoggerWeb.Plugs.Authorize, :edit_own_profile)
  end

  pipeline :can_view_stats do
    plug(MailgunLoggerWeb.Plugs.Authorize, :view_stats)
  end

  pipeline :can_manage_accounts do
    plug(MailgunLoggerWeb.Plugs.Authorize, :manage_accounts)
  end

  pipeline :can_manage_users do
    plug(MailgunLoggerWeb.Plugs.Authorize, :manage_users)
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
    get("/non-affiliation", PageController, :non_affiliation)
    post("/", SetupController, :create_root)
  end

  scope "/", MailgunLoggerWeb do
    pipe_through([:browser, :auth, :can_view_events])

    get("/", PageController, :index)
    get("/events", EventController, :index)
  end

  scope "/", MailgunLoggerWeb do
    pipe_through([:browser, :auth, :can_view_event_details])

    get("/events/:id", EventController, :show)
    get("/events/:id/stored_message", EventController, :stored_message)
  end

  scope "/", MailgunLoggerWeb do
    pipe_through([:browser, :auth, :can_edit_own_profile])

    get("/profile", ProfileController, :edit)
    put("/profile", ProfileController, :update)
  end

  scope "/", MailgunLoggerWeb do
    pipe_through([:browser, :auth])

    get("/logout", AuthController, :logout)
  end

  scope "/", MailgunLoggerWeb do
    pipe_through([:browser, :auth, :can_view_stats])

    get("/stats", PageController, :stats)
    get("/graphs", PageController, :graphs)
    post("/trigger-run", PageController, :trigger_run)
  end

  scope "/", MailgunLoggerWeb do
    pipe_through([:browser, :auth, :can_manage_accounts])

    resources("/accounts", AccountController, except: [:show])
  end

  scope "/", MailgunLoggerWeb do
    pipe_through([:browser, :auth, :can_manage_users])

    resources("/users", UserController, except: [:show])
  end
end
