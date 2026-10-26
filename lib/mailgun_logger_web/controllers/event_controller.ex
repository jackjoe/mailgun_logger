defmodule MailgunLoggerWeb.EventController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Events
  alias MailgunLogger.Accounts

  def index(conn, params) do
    accounts = Accounts.list_accounts()

    case Events.search_events(params) do
      {:ok, {events, meta}} ->
        render(conn, :index, [meta: meta, events: events, accounts: accounts] ++ run_status())

      {:error, %Flop.Meta{} = meta} ->
        conn
        |> put_flash(:error, "Something went wrong")
        |> put_status(500)
        |> render(:index, [meta: meta, events: [], accounts: accounts] ++ run_status())
    end
  end

  defp run_status() do
    [running?: MailgunLogger.running?(), last_run: Accounts.last_run_summary()]
  end

  def show(conn, %{"id" => event_id}) do
    event = event_id |> Events.get_event() |> Events.preload(:account)
    render(conn, :show, event: event)
  end

  def stored_message(conn, %{"id" => event_id}) do
    event = Events.get_event(event_id)

    if event.has_stored_message do
      content = Mailgun.Events.get_stored_message_content(event)
      content = String.replace(content, "bgcolor", "_bgcolor")

      html(conn, content)
    else
      redirect(conn, to: ~p"/events")
    end
  end
end
