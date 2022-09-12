defmodule MailgunLoggerWeb.PageController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Events
  alias MailgunLogger.Accounts

  def index(conn, _) do
    total_accounts = Accounts.list_accounts() |> length()
    stats = Events.get_stats(24)
    IO.inspect(stats)

    event_counts = %{
      total: Events.get_total_events(),
      by_type: Events.get_event_counts_by_type()
    }

    render(conn, :index, total_accounts: total_accounts, event_counts: event_counts, stats: stats)
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
