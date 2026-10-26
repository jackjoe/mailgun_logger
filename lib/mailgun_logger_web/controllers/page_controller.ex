defmodule MailgunLoggerWeb.PageController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Events
  alias MailgunLogger.Accounts

  def index(conn, _) do
    redirect(conn, to: ~p"/events")
  end

  def trigger_run(conn, _) do
    # run the task to fetch new emails
    MailgunLogger.run_async_if_not_running()
    conn = put_flash(conn, :info, "Run started")

    # redirect to the current page to preserve the search query parameters
    case List.keyfind(conn.req_headers, "referer", 0) do
      {"referer", path} ->
        redirect(conn, external: path)

      _ ->
        redirect(conn, to: ~p"/events")
    end
  end

  @ranges ~w(24h 7d 30d)

  def stats(conn, params) do
    range = if params["range"] in @ranges, do: params["range"], else: "24h"
    accounts = Accounts.list_accounts()
    account_id = Enum.find_value(accounts, &(to_string(&1.id) == params["account_id"] && &1.id))

    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    period = Events.stats_period(range, now)
    %{from: from, to: to} = period

    render(conn, :stats,
      ranges: @ranges,
      range: range,
      accounts: accounts,
      account_id: account_id,
      period: period,
      counts: Events.count_events_by_type(from, to, account_id),
      previous: Events.count_events_by_type(period.previous_from, from, account_id),
      volume: Events.event_volume(from, to, period.bucket, account_id),
      reasons: Events.top_failure_reasons(from, to, account_id, 10),
      domains: Events.top_failing_domains(from, to, account_id, 10)
    )
  end

  def graphs(conn, _) do
    redirect(conn, to: ~p"/stats")
  end

  def non_affiliation(conn, _) do
    render(conn, :non_affiliation)
  end
end
