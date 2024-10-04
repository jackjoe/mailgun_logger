defmodule MailgunLoggerWeb.PageController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Events
  alias MailgunLogger.Accounts
  alias MailgunLogger.Roles

  plug(:authorize)

  defp authorize(conn, _options) do
    action = Phoenix.Controller.action_name(conn)
    current_user = conn.assigns.current_user

    case action do
      :index ->
        conn

      :trigger_run ->
        if Roles.can?(current_user, :trigger_run), do: conn, else: conn |> resp(403, []) |> halt()

      :stats ->
        if Roles.can?(current_user, :view_stats), do: conn, else: conn |> resp(403, []) |> halt()

      :graphs ->
        if Roles.can?(current_user, :view_graphs), do: conn, else: conn |> resp(403, []) |> halt()

      :non_affiliation ->
        conn

      _ ->
        conn |> resp(403, []) |> halt()
    end
  end

  def index(conn, _) do
    redirect(conn, to: Routes.event_path(conn, :index))
  end

  def trigger_run(conn, _) do
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

  def stats(conn, _) do
    total_accounts = Accounts.list_accounts() |> length()

    event_counts = %{
      total: Events.get_total_events(),
      by_type: Events.get_event_counts_by_type()
    }

    render(conn, :stats, total_accounts: total_accounts, event_counts: event_counts)
  end

  def graphs(conn, _) do
    stats = Events.get_stats(24)
    render(conn, :graphs, stats: stats)
  end

  def non_affiliation(conn, _) do
    render(conn, :non_affiliation)
  end
end
