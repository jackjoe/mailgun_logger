defmodule MailgunLoggerWeb.PageController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Roles
  alias MailgunLogger.Events
  alias MailgunLogger.Accounts

  defp authorize!(conn, action) do
  user = conn.assigns.current_user

  if Roles.can?(user, action) do
    conn
  else
    conn
    |> put_flash(:error, "Not authorized")
    |> redirect(to: Routes.event_path(conn, :index))
    |> halt()
  end
end

  def index(conn, _) do
    redirect(conn, to: Routes.event_path(conn, :index))
  end

  def trigger_run(conn, _) do
    conn = authorize!(conn, :do_stuff)

    if conn.halted do
      conn
    else
      # run the task to fetch new emails
      MailgunLogger.run_async_if_not_running()

      # redirect to the current page to preserve the search query parameters
      case List.keyfind(conn.req_headers, "referer", 0) do
        {"referer", path} ->
          redirect(conn, external: path)

        _ ->
          redirect(conn, to: Routes.event_path(conn, :index))
      end
    end
  end

  def stats(conn, _) do
    conn = authorize!(conn, :view_stats)

    if conn.halted do
      conn
    else
      total_accounts = Accounts.count_accounts()

      event_counts = %{
        total: Events.get_total_events(),
        by_type: Events.get_event_counts_by_type()
      }

      render(conn, :stats, total_accounts: total_accounts, event_counts: event_counts)
    end
  end

  def graphs(conn, _) do

    conn = authorize!(conn, :view_stats)

    if conn.halted do
      conn
    else
      stats = Events.get_stats(24)
      render(conn, :graphs, stats: stats)
    end
  end

  def non_affiliation(conn, _) do
    render(conn, :non_affiliation)
  end
end
