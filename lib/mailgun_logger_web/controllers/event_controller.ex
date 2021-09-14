defmodule MailgunLoggerWeb.EventController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Events

  def index(conn, params) do
    IO.inspect(params, label: "INDEX")
    page = Events.search_events(params)

    render(conn, :index, page: page)
  end

  def show(conn, %{"id" => event_id}) do
    event = event_id |> Events.get_event() |> Events.preload(:account)
    render(conn, :show, event: event)
  end

  def stored_message(conn, %{"id" => event_id}) do
    event = Events.get_event(event_id)

    case event.stored_message do
      nil ->
        redirect(conn, to: Routes.event_path(conn, :index))

      %{"body-html" => html} ->
        conn
        |> put_layout(false)
        |> render(:stored_message, html: html)
    end
  end
end
