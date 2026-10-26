defmodule MailgunLogger.EventsTest do
  use MailgunLogger.DataCase

  alias MailgunLogger.Events

  describe "search_events/2 page size" do
    setup do
      page_size = Application.get_env(:mailgun_logger, :page_size)
      on_exit(fn -> Application.put_env(:mailgun_logger, :page_size, page_size) end)
    end

    test "uses the page size from the application environment at runtime" do
      account = insert(:account)
      insert_list(5, :event, account: account)

      Application.put_env(:mailgun_logger, :page_size, 3)

      {:ok, {page, meta}} = Events.search_events(%{})
      assert length(page) == 3
      assert meta.has_next_page?
    end
  end

  describe "search_events/2 time range" do
    setup do
      account = insert(:account)

      for {hour, subject} <- [{8, "early"}, {10, "middle"}, {12, "late"}] do
        insert(:event,
          account: account,
          message_subject: subject,
          timestamp: NaiveDateTime.new!(~D[2026-10-26], Time.new!(hour, 0, 0))
        )
      end

      :ok
    end

    defp subjects(filters) do
      {:ok, {events, _meta}} = Events.search_events(%{"filters" => filters})
      events |> Enum.map(& &1.message_subject) |> Enum.sort()
    end

    test "from a time" do
      filters = %{"0" => %{"field" => "timestamp", "op" => ">=", "value" => "2026-10-26T10:00"}}
      assert subjects(filters) == ["late", "middle"]
    end

    test "until a time" do
      filters = %{"0" => %{"field" => "timestamp", "op" => "<=", "value" => "2026-10-26T10:00"}}
      assert subjects(filters) == ["early", "middle"]
    end

    test "between two times" do
      filters = %{
        "0" => %{"field" => "timestamp", "op" => ">=", "value" => "2026-10-26T09:00"},
        "1" => %{"field" => "timestamp", "op" => "<=", "value" => "2026-10-26T11:00"}
      }

      assert subjects(filters) == ["middle"]
    end
  end

  describe "export_csv/3" do
    defp export(params, limit) do
      {:ok, lines} = Events.export_csv(params, limit, &Enum.to_list/1)
      lines |> IO.iodata_to_binary() |> String.split("\r\n", trim: true)
    end

    test "writes a header and one line per matching event, newest first" do
      account = insert(:account, domain: "mg.example.com")

      insert(:event,
        account: account,
        event: "failed",
        timestamp: ~N[2026-10-26 10:00:00],
        message_subject: "Hello, \"you\"",
        raw: %{"delivery-status" => %{"message" => "mailbox full"}}
      )

      insert(:event, account: account, event: "delivered", timestamp: ~N[2026-10-26 09:00:00])
      insert(:event, account: account, event: "opened", timestamp: ~N[2026-10-26 11:00:00])

      filters = %{"0" => %{"field" => "event", "op" => "in", "value" => ["failed", "delivered"]}}
      [header | lines] = export(%{"filters" => filters}, 10)

      assert header ==
               "timestamp_utc,event,log_level,method,account,from,recipient,subject,message_id,failure_reason"

      assert [failed, delivered] = lines
      assert failed =~ ~s(2026-10-26 10:00:00,failed,info,http,mg.example.com,)
      assert failed =~ ~s("Hello, ""you""")
      assert failed =~ ~s(,mailbox full)
      assert delivered =~ "2026-10-26 09:00:00,delivered,"
    end

    test "stops at the limit" do
      insert_list(3, :event)
      assert length(export(%{}, 2)) == 3
    end

    test "neutralizes values that a spreadsheet would run as a formula" do
      insert(:event, message_subject: "=HYPERLINK(1)")
      [_header, line] = export(%{}, 10)
      assert line =~ ",'=HYPERLINK(1),"
    end
  end

  describe "search_events/2 cursor pagination" do
    test "next page returns rows that are not on the previous page" do
      account = insert(:account)

      for i <- 1..30 do
        insert(:event,
          account: account,
          timestamp: NaiveDateTime.add(~N[2026-01-01 00:00:00], i, :second)
        )
      end

      {:ok, {page1, meta1}} = Events.search_events(%{"first" => 10})
      assert length(page1) == 10
      assert meta1.has_next_page?
      assert is_binary(meta1.end_cursor)

      {:ok, {page2, meta2}} = Events.search_events(%{"first" => 10, "after" => meta1.end_cursor})
      assert length(page2) == 10

      page1_ids = Enum.map(page1, & &1.id)
      page2_ids = Enum.map(page2, & &1.id)

      assert MapSet.disjoint?(MapSet.new(page1_ids), MapSet.new(page2_ids)),
             "page 2 must not repeat ids from page 1, got overlap: " <>
               inspect(MapSet.intersection(MapSet.new(page1_ids), MapSet.new(page2_ids)))

      {:ok, {page3, _meta3}} = Events.search_events(%{"first" => 10, "after" => meta2.end_cursor})
      page3_ids = Enum.map(page3, & &1.id)

      assert MapSet.disjoint?(MapSet.new(page2_ids), MapSet.new(page3_ids)),
             "page 3 must not repeat ids from page 2, got overlap: " <>
               inspect(MapSet.intersection(MapSet.new(page2_ids), MapSet.new(page3_ids)))

      assert MapSet.equal?(
               MapSet.new(page1_ids ++ page2_ids ++ page3_ids),
               MapSet.new(page1_ids ++ page2_ids ++ page3_ids) |> MapSet.to_list() |> MapSet.new()
             )

      assert length(page1_ids ++ page2_ids ++ page3_ids) == 30
    end

    test "rows are ordered by timestamp descending across pages" do
      account = insert(:account)

      for i <- 1..30 do
        insert(:event,
          account: account,
          timestamp: NaiveDateTime.add(~N[2026-01-01 00:00:00], i, :second)
        )
      end

      {:ok, {page1, meta1}} = Events.search_events(%{"first" => 10})
      {:ok, {page2, _meta2}} = Events.search_events(%{"first" => 10, "after" => meta1.end_cursor})

      last_of_page1 = List.last(page1).timestamp
      first_of_page2 = List.first(page2).timestamp

      assert NaiveDateTime.compare(first_of_page2, last_of_page1) in [:lt, :eq],
             "expected page 2 to continue chronologically after page 1, " <>
               "but page 1 ends at #{last_of_page1} and page 2 starts at #{first_of_page2}"
    end
  end
end
