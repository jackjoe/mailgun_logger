defmodule MailgunLoggerWeb.EventController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Event
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

  @export_limit 100_000

  def export(conn, params) do
    conn =
      conn
      |> put_resp_content_type("text/csv")
      |> put_resp_header("content-disposition", ~s(attachment; filename="events.csv"))
      |> send_chunked(200)

    {:ok, conn} =
      Events.export_csv(params, @export_limit, fn lines ->
        lines
        |> Stream.chunk_every(500)
        |> Enum.reduce_while(conn, fn chunk, conn ->
          case chunk(conn, chunk) do
            {:ok, conn} -> {:cont, conn}
            {:error, :closed} -> {:halt, conn}
          end
        end)
      end)

    conn
  end

  def show(conn, %{"id" => event_id}) do
    event = event_id |> Events.get_event() |> Events.preload(:account)
    render(conn, :show, event: event)
  end

  def stored_message(conn, %{"id" => event_id}) do
    with %Event{} = event <- Events.get_event(event_id),
         event = Events.preload(event, :account),
         client = Mailgun.Client.new(event.account),
         {:ok, content} <- Mailgun.Events.get_stored_message_content(event, client) do
      html(conn, String.replace(content, "bgcolor", "_bgcolor"))
    else
      _ ->
        conn
        |> put_status(:not_found)
        |> text("Stored message not available. Mailgun keeps a message for a few days only.")
    end
  end
end
