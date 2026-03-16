defmodule MailgunLoggerWeb.EventController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Events
  alias MailgunLogger.Accounts
  alias MailgunLogger.Roles

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

  def index(conn, params) do
    conn = authorize!(conn, :view_events)

    if conn.halted do
      conn
    else
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
  end

  def show(conn, %{"id" => event_id}) do
    conn = authorize!(conn, :view_events)

    if conn.halted do
      conn
    else
      event = event_id |> Events.get_event() |> Events.preload(:account)
      render(conn, :show, event: event)
    end
  end

  def stored_message(conn, %{"id" => event_id}) do
    conn = authorize!(conn, :view_events)

    if conn.halted do
      conn
    else
      event = Events.get_event(event_id)

      if event.has_stored_message do
        content = Mailgun.Events.get_stored_message_content(event)
        content = String.replace(content, "bgcolor", "_bgcolor")

        conn
        |> put_layout(false)
        |> render(:stored_message, html: content)
      else
        redirect(conn, to: Routes.event_path(conn, :index))
      end
    end
  end
end
