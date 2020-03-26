defmodule MailgunLoggerWeb.PageController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Events
  alias MailgunLogger.Accounts

  def index(conn, _) do
    total_events = Events.get_total_events()
    total_accounts = Accounts.list_accounts() |> length()
    render(conn, :index, total_events: total_events, total_accounts: total_accounts)
  end

  def non_affiliation(conn, _) do
    render(conn, :non_affiliation)
  end

  def trigger_run(conn, _) do
    Task.start(&MailgunLogger.run/0)

    conn
    |> put_flash(:info, "Run triggered successfully. Data should be coming in...")
    |> redirect(to: Routes.page_path(conn, :index))
  end
end
