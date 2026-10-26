defmodule MailgunLoggerWeb.EventControllerTest do
  use MailgunLoggerWeb.ConnCase

  setup :log_in_user

  test "lists the events", %{conn: conn} do
    event = insert(:event)
    conn = get(conn, ~p"/events")
    html = html_response(conn, 200)
    assert headings(html) == ["Events"]
    assert html =~ event.recipient
    assert html =~ ~s(href="/events/#{event.id}")
  end

  test "filters the events", %{conn: conn} do
    delivered = insert(:event, event: "delivered")
    failed = insert(:event, event: "failed")

    conn =
      get(conn, ~p"/events", %{
        "filters" => %{"0" => %{"field" => "event", "op" => "==", "value" => "failed"}}
      })

    html = html_response(conn, 200)
    assert html =~ failed.recipient
    refute html =~ delivered.recipient
  end

  describe "run status" do
    defp run_status(conn) do
      conn
      |> get(~p"/events")
      |> html_response(200)
      |> LazyHTML.from_document()
      |> LazyHTML.query(".run-status")
      |> LazyHTML.text()
      |> String.split()
      |> Enum.join(" ")
    end

    test "shows a run in progress", %{conn: conn} do
      pid = spawn(fn -> Process.sleep(:infinity) end)
      Process.register(pid, :run_task)
      on_exit(fn -> Process.exit(pid, :kill) end)

      assert run_status(conn) == "Run in progress"
    end

    test "shows a summary of the last run", %{conn: conn} do
      insert(:account,
        last_run_at: DateTime.add(DateTime.utc_now(), -600, :second),
        last_run_status: "ok"
      )

      insert(:account,
        last_run_at: DateTime.add(DateTime.utc_now(), -180, :second),
        last_run_status: "error"
      )

      assert run_status(conn) == "Last run 3 min ago: 1 ok, 1 error"
    end

    test "shows nothing before the first run", %{conn: conn} do
      insert(:account)
      assert run_status(conn) == ""
    end
  end

  test "the account filter defaults to all accounts", %{conn: conn} do
    html = conn |> get(~p"/events") |> html_response(200)

    options =
      html
      |> LazyHTML.from_document()
      |> LazyHTML.query(~s(select[name="filters[4][value]"] option))
      |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))

    assert hd(options) == "all"
  end

  test "has since and until inputs in UTC", %{conn: conn} do
    html = conn |> get(~p"/events") |> html_response(200)
    doc = LazyHTML.from_document(html)

    inputs =
      doc
      |> LazyHTML.query(~s(#events-filter input[type="datetime-local"]))
      |> Enum.map(&{LazyHTML.attribute(&1, "title"), LazyHTML.attribute(&1, "name")})

    assert [{["Since (UTC)"], [_]}, {["Until (UTC)"], [_]}] = inputs
  end

  test "keeps the time range in the pagination links", %{conn: conn} do
    insert_list(51, :event, timestamp: ~N[2026-10-26 10:00:00])

    filters = %{"0" => %{"field" => "timestamp", "op" => ">=", "value" => "2026-10-26T09:00"}}

    next =
      conn
      |> get(~p"/events", %{"filters" => filters})
      |> html_response(200)
      |> pagination_href("Next")

    assert %{
             "filters[0][field]" => "timestamp",
             "filters[0][op]" => ">=",
             "filters[0][value]" => "2026-10-26T09:00:00"
           } = decode_query(next)
  end

  describe "pagination" do
    test "links to the next and previous page without empty parameters", %{conn: conn} do
      account = insert(:account)
      insert_list(51, :event, account: account)

      next = conn |> get(~p"/events") |> html_response(200) |> pagination_href("Next")
      assert %{"after" => _} = query = decode_query(next)
      refute Enum.any?(query, fn {_key, value} -> value == "" end), "empty parameter in #{next}"

      previous = conn |> get(next) |> html_response(200) |> pagination_href("Previous")
      assert %{"before" => _} = query = decode_query(previous)

      refute Enum.any?(query, fn {_key, value} -> value == "" end),
             "empty parameter in #{previous}"
    end
  end

  defp decode_query(href), do: href |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()

  defp pagination_href(html, label) do
    html
    |> LazyHTML.from_document()
    |> LazyHTML.query(".pagination-wrapper a")
    |> Enum.find(&(LazyHTML.text(&1) =~ label))
    |> LazyHTML.attribute("href")
    |> hd()
  end

  test "shows an event", %{conn: conn} do
    event = insert(:event, raw: %{"event" => "delivered"})
    conn = get(conn, ~p"/events/#{event}")
    html = html_response(conn, 200)
    assert html =~ "<dt>Recipient</dt>"
    assert html =~ event.recipient
    assert html =~ event.account.domain
    assert html =~ ~s(<code style="white-space: break-spaces">{\n)
    assert html =~ ~r{<dt>Linked events</dt>\s*<dd>\s*<span>none</span>}
  end

  test "highlights the events link in the navigation", %{conn: conn} do
    conn = get(conn, ~p"/events")
    assert html_response(conn, 200) =~ ~s(<a href="/events" class="is-active">Events</a>)
  end

  test "redirects when the event has no stored message", %{conn: conn} do
    event = insert(:event)
    conn = get(conn, ~p"/events/#{event}/stored_message")
    assert redirected_to(conn) == ~p"/events"
  end
end
