defmodule MailgunLoggerWeb.EventController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Events
  alias MailgunLogger.Accounts

  def index(conn, params) do
    accounts = Accounts.list_accounts()

    case Events.search_events(params) do
      {:ok, {events, meta}} ->
        render(conn, :index, meta: meta, events: events, accounts: accounts)

      {:error, %Flop.Meta{} = meta} ->
        conn
        |> put_flash(:error, "Something went wrong")
        |> put_status(500)
        |> render(:index, meta: meta, events: [], accounts: accounts)
    end
  end

  def show(conn, %{"id" => event_id}) do
    event = event_id |> Events.get_event() |> Events.preload(:account)
    render(conn, :show, event: event)
  end

  def stored_message(conn, %{"id" => event_id}) do
    event = Events.get_event(event_id)

    if event.has_stored_message do
      html = Mailgun.Events.get_stored_message_html(event)
      html = String.replace(html, "bgcolor", "_bgcolor")

      conn
      |> put_layout(false)
      |> render(:stored_message, html: html)
    else
      redirect(conn, to: Routes.event_path(conn, :index))
    end
  end
end
