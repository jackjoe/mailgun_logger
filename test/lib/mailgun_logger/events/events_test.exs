defmodule MailgunLogger.EventsTest do
  use MailgunLogger.DataCase

  alias MailgunLogger.Events

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
