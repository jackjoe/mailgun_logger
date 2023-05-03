defmodule MailgunLoggerWeb.EventController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Events
  alias MailgunLogger.Accounts

  def index(conn, params) do
    accounts = Accounts.list_accounts() |> Enum.map(&{&1.domain, &1.id})
    page = Events.search_events(params)
    render(conn, :index, page: page, accounts: accounts)
  end

  def show(conn, %{"id" => event_id}) do
    event = event_id |> Events.get_event() |> Events.preload(:account)
    render(conn, :show, event: event)
  end

  def stored_message(conn, %{"id" => event_id}) do
    event = Events.get_event(event_id)

    if event.has_stored_message do
      html = Mailgun.Events.get_stored_message_html(event)

      conn
      |> put_layout(false)
      |> render(:stored_message, html: html)
    else
      redirect(conn, to: Routes.event_path(conn, :index))
    end
  end
end
