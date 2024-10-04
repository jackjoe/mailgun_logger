defmodule MailgunLoggerWeb.EventController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Events
  alias MailgunLogger.Accounts
  alias MailgunLogger.Event
  alias MailgunLogger.Roles

  plug(:authorize)

  defp authorize(conn, _options) do
    action = Phoenix.Controller.action_name(conn)
    current_user = conn.assigns.current_user

    if Roles.can?(current_user, action, Event) do
      conn
    else
      # TODO: better handling of error pages
      conn |> resp(403, []) |> halt()
    end
  end

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
