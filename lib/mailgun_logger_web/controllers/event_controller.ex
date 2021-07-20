defmodule MailgunLoggerWeb.EventController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Events

  def index(conn, params) do
    events = Events.search_events(params)

    render(conn, :index,
      page: %Pager.Page{
        entries: events,
        next: nil,
        previous: nil
      }
    )
  end

  def show(conn, %{"id" => event_id}) do
    event = Events.get_event(event_id) |> Events.preload(:account)
    render(conn, :show, event: event)
  end
end
