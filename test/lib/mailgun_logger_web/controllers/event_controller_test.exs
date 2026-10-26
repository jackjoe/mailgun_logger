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

  describe "rows" do
    defp first_row(conn, path) do
      conn
      |> get(path)
      |> html_response(200)
      |> LazyHTML.from_document()
      |> LazyHTML.query(".log-row")
      |> Enum.at(0)
    end

    defp href_filters(node, selector) do
      [href] = node |> LazyHTML.query(selector) |> LazyHTML.attribute("href")
      query = href |> URI.parse() |> Map.fetch!(:query) |> Plug.Conn.Query.decode()
      query |> Map.get("filters", %{}) |> Map.values() |> Enum.sort_by(& &1["field"])
    end

    test "links the sender, recipient and event to a filter that keeps the other filters",
         %{conn: conn} do
      event = insert(:event, event: "delivered", message_from: "a@x.com", recipient: "b@y.com")

      account = %{"field" => "account_id", "op" => "==", "value" => to_string(event.account_id)}
      row = first_row(conn, ~p"/events?#{%{filters: %{"0" => account}}}")

      assert href_filters(row, ".log-col-from a") == [
               account,
               %{"field" => "message_from", "op" => "ilike", "value" => "a@x.com"}
             ]

      assert href_filters(row, ".log-col-to a") == [
               account,
               %{"field" => "recipient", "op" => "ilike", "value" => "b@y.com"}
             ]

      assert href_filters(row, ".log-col-event a") == [
               account,
               %{"field" => "event", "op" => "==", "value" => "delivered"}
             ]
    end

    test "a new filter replaces a filter on the same field", %{conn: conn} do
      insert(:event, event: "delivered")
      old = %{"field" => "event", "op" => "==", "value" => "failed"}

      row = first_row(conn, ~p"/events")
      assert [%{"value" => "delivered"}] = href_filters(row, ".log-col-event a")

      insert(:event, event: "failed")
      row = first_row(conn, ~p"/events?#{%{filters: %{"0" => old}}}")
      assert [%{"value" => "failed"}] = href_filters(row, ".log-col-event a")
    end

    test "shows the failure reason of a failed event", %{conn: conn} do
      insert(:event, event: "failed", raw: %{"delivery-status" => %{"message" => "mailbox full"}})
      row = first_row(conn, ~p"/events")

      assert row |> LazyHTML.query(".failure-reason") |> LazyHTML.text() =~ "mailbox full"
      assert [title] = row |> LazyHTML.query(".log-col-event a") |> LazyHTML.attribute("title")
      assert title =~ "mailbox full"
    end

    test "shows no failure reason for a delivered event", %{conn: conn} do
      insert(:event, event: "delivered", raw: %{"delivery-status" => %{"message" => "OK"}})
      row = first_row(conn, ~p"/events")
      assert row |> LazyHTML.query(".failure-reason") |> Enum.count() == 0
    end

    test "shows the UTC time with the relative time as tooltip", %{conn: conn} do
      insert(:event, timestamp: ~N[2026-10-01 02:10:00])

      [time] =
        conn |> first_row(~p"/events") |> LazyHTML.query(".log-col-ts time") |> Enum.to_list()

      assert time |> LazyHTML.text() |> String.trim() == "2026-10-01 02:10:00"
      assert [title] = LazyHTML.attribute(time, "title")
      assert title =~ "ago"
    end
  end

  describe "page size" do
    defp rows(html),
      do: html |> LazyHTML.from_document() |> LazyHTML.query(".log-row") |> Enum.count()

    test "shows the chosen page size", %{conn: conn} do
      insert_list(3, :event)
      assert conn |> get(~p"/events?first=2") |> html_response(200) |> rows() == 2
    end

    test "falls back to the default page size above 250", %{conn: conn} do
      page_size = Application.get_env(:mailgun_logger, :page_size)
      Application.put_env(:mailgun_logger, :page_size, 2)
      on_exit(fn -> Application.put_env(:mailgun_logger, :page_size, page_size) end)

      insert_list(3, :event)
      html = conn |> get(~p"/events?first=251") |> html_response(200)
      assert rows(html) == 2
      refute html =~ "Something went wrong"
    end

    test "links to each page size and keeps the filters", %{conn: conn} do
      failed = %{"field" => "event", "op" => "==", "value" => "failed"}
      html = conn |> get(~p"/events?#{%{filters: %{"0" => failed}}}") |> html_response(200)

      links =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(".page-size a")
        |> Enum.map(fn link ->
          [href] = LazyHTML.attribute(link, "href")
          query = href |> URI.parse() |> Map.fetch!(:query) |> Plug.Conn.Query.decode()
          {String.trim(LazyHTML.text(link)), query["first"], Map.values(query["filters"])}
        end)

      assert links == [
               {"50", "50", [failed]},
               {"100", "100", [failed]},
               {"250", "250", [failed]}
             ]
    end

    test "the filter form keeps a chosen page size", %{conn: conn} do
      html = conn |> get(~p"/events?first=100") |> html_response(200)

      assert html
             |> LazyHTML.from_document()
             |> LazyHTML.query(~s(#events-filter input[name="first"]))
             |> LazyHTML.attribute("value") == ["100"]
    end
  end

  describe "CSV export" do
    test "downloads the filtered events", %{conn: conn} do
      insert(:event, event: "failed", recipient: "failed@example.com")
      insert(:event, event: "delivered", recipient: "delivered@example.com")

      failed = %{"field" => "event", "op" => "==", "value" => "failed"}
      conn = get(conn, ~p"/events/export.csv?#{%{filters: %{"0" => failed}}}")

      assert response_content_type(conn, :csv) =~ "text/csv"

      assert [~s(attachment; filename="events.csv")] =
               get_resp_header(conn, "content-disposition")

      body = response(conn, 200)
      assert body =~ "failed@example.com"
      refute body =~ "delivered@example.com"
    end

    test "the events page links to the export with the same filters", %{conn: conn} do
      failed = %{"field" => "event", "op" => "==", "value" => "failed"}
      html = conn |> get(~p"/events?#{%{filters: %{"0" => failed}}}") |> html_response(200)

      [href] =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("a.export")
        |> LazyHTML.attribute("href")

      query = href |> URI.parse() |> Map.fetch!(:query) |> Plug.Conn.Query.decode()
      assert URI.parse(href).path == "/events/export.csv"
      assert Map.values(query["filters"]) == [failed]
    end
  end

  describe "message filter" do
    test "the filter form keeps the message filter", %{conn: conn} do
      message = %{"field" => "message_id", "op" => "==", "value" => "abc@mg.example.com"}
      html = conn |> get(~p"/events?#{%{filters: %{"0" => message}}}") |> html_response(200)

      hidden =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query(~s(#events-filter input[type="hidden"][name^="filters"]))
        |> Enum.map(&{hd(LazyHTML.attribute(&1, "name")), hd(LazyHTML.attribute(&1, "value"))})
        |> Enum.filter(fn {name, _} -> name =~ "[message_id]" or name =~ "filters[99]" end)

      assert hidden == [
               {"filters[99][field]", "message_id"},
               {"filters[99][op]", "=="},
               {"filters[99][value]", "abc@mg.example.com"}
             ]
    end

    test "the detail page links to all events of the message", %{conn: conn} do
      event = insert(:event, message_id: "abc@mg.example.com")
      html = conn |> get(~p"/events/#{event}") |> html_response(200)

      [href] =
        html
        |> LazyHTML.from_document()
        |> LazyHTML.query("a.message-events")
        |> LazyHTML.attribute("href")

      query = href |> URI.parse() |> Map.fetch!(:query) |> Plug.Conn.Query.decode()

      assert Map.values(query["filters"]) == [
               %{"field" => "message_id", "op" => "==", "value" => "abc@mg.example.com"}
             ]
    end

    test "lists the events of one message and shows the filter with a remove link", %{
      conn: conn
    } do
      insert(:event, message_id: "abc@mg.example.com", recipient: "one@example.com")
      insert(:event, message_id: "other@mg.example.com", recipient: "two@example.com")

      message = %{"field" => "message_id", "op" => "==", "value" => "abc@mg.example.com"}
      failed = %{"field" => "event", "op" => "==", "value" => "delivered"}

      html =
        conn
        |> get(~p"/events?#{%{filters: %{"0" => message, "1" => failed}}}")
        |> html_response(200)

      assert html =~ "one@example.com"
      refute html =~ "two@example.com"

      chip = html |> LazyHTML.from_document() |> LazyHTML.query(".active-filter")
      assert LazyHTML.text(chip) =~ "abc@mg.example.com"

      [href] = chip |> LazyHTML.query("a") |> LazyHTML.attribute("href")
      query = href |> URI.parse() |> Map.fetch!(:query) |> Plug.Conn.Query.decode()
      assert Map.values(query["filters"]) == [failed]
    end
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
    assert html =~ ~s(<code id="raw-json" style="white-space: break-spaces">{\n)
  end

  test "highlights the events link in the navigation", %{conn: conn} do
    conn = get(conn, ~p"/events")
    assert html_response(conn, 200) =~ ~s(<a href="/events" class="is-active">Events</a>)
  end

  describe "detail page" do
    test "shows the events of the message as a timeline, oldest first", %{conn: conn} do
      account = insert(:account)
      attrs = [account: account, message_id: "m1@example.com"]
      insert(:event, attrs ++ [event: "opened", timestamp: ~N[2026-10-01 02:30:00]])
      event = insert(:event, attrs ++ [event: "delivered", timestamp: ~N[2026-10-01 02:10:00]])
      insert(:event, attrs ++ [event: "accepted", timestamp: ~N[2026-10-01 02:00:00]])

      items =
        conn
        |> get(~p"/events/#{event}")
        |> html_response(200)
        |> LazyHTML.from_document()
        |> LazyHTML.query(".timeline li")
        |> Enum.map(&(&1 |> LazyHTML.text() |> String.split() |> Enum.join(" ")))

      assert items == [
               "2026-10-01 02:00:00 accepted",
               "2026-10-01 02:10:00 delivered this event",
               "2026-10-01 02:30:00 opened"
             ]
    end

    test "works for an event without a message ID", %{conn: conn} do
      event = insert(:event, message_id: nil)
      html = conn |> get(~p"/events/#{event}") |> html_response(200)
      assert html =~ "this event"
    end

    test "shows the raw event folded, with a copy button", %{conn: conn} do
      event = insert(:event, raw: %{"event" => "delivered"})

      doc = conn |> get(~p"/events/#{event}") |> html_response(200) |> LazyHTML.from_document()

      assert doc |> LazyHTML.query("details.raw-event code#raw-json") |> LazyHTML.text() =~
               ~s("event": "delivered")

      assert doc |> LazyHTML.query("details.raw-event button") |> LazyHTML.attribute("data-copy") ==
               ["#raw-json"]
    end
  end

  test "redirects when the event has no stored message", %{conn: conn} do
    event = insert(:event)
    conn = get(conn, ~p"/events/#{event}/stored_message")
    assert redirected_to(conn) == ~p"/events"
  end
end
