defmodule MailgunLoggerWeb.PageController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Events

  def index(conn, _) do
    total_events = Events.get_total_events()
    render(conn, :index, total_events: total_events)
  end

  def non_affiliation(conn, _) do
    render(conn, :non_affiliation)
  end
end
