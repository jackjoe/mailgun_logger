defmodule MailgunLoggerWeb.EventController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Events

  def index(conn, %{"q" => q} = params) do
    page = Events.list_events_paged(params, q)
    render(conn, :index, page: page)
  end

  def index(conn, params) do
    page = Events.list_events_paged(params, "")
    render(conn, :index, page: page)
  end

  def show(conn, %{"id" => event_id}) do
    event = Events.get_event(event_id) |> Events.preload(:account)
    render(conn, :show, event: event)
  end
end
