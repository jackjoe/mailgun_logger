defmodule MailgunLogger.Events.StatsTest do
  use MailgunLogger.DataCase

  alias MailgunLogger.Events

  @from ~N[2026-10-26 08:00:00]
  @to ~N[2026-10-26 12:00:00]

  defp event(attrs) do
    insert(:event, Keyword.merge([timestamp: ~N[2026-10-26 09:15:00]], attrs))
  end

  defp failed(reason, recipient, attrs \\ []) do
    raw = %{"delivery-status" => %{"message" => reason}}
    event(Keyword.merge([event: "failed", raw: raw, recipient: recipient], attrs))
  end

  describe "stats_period/2" do
    @now ~N[2026-10-26 12:34:56]

    test "24h counts per hour" do
      assert Events.stats_period("24h", @now) == %{
               from: ~N[2026-10-25 12:34:56],
               to: @now,
               previous_from: ~N[2026-10-24 12:34:56],
               bucket: "hour"
             }
    end

    test "7d and 30d count per day" do
      assert %{from: ~N[2026-10-19 12:34:56], bucket: "day"} = Events.stats_period("7d", @now)
      assert %{from: ~N[2026-09-26 12:34:56], bucket: "day"} = Events.stats_period("30d", @now)
    end

    test "an unknown range falls back to 24h" do
      assert Events.stats_period("1y", @now) == Events.stats_period("24h", @now)
    end
  end

  test "count_events_by_type/3 counts in the period and for one account" do
    account = insert(:account)
    event(event: "delivered", account: account)
    event(event: "delivered")
    event(event: "failed", account: account)
    event(event: "delivered", timestamp: ~N[2026-10-26 07:59:59])
    event(event: "delivered", timestamp: @to)

    assert Events.count_events_by_type(@from, @to, nil) == %{"delivered" => 2, "failed" => 1}

    assert Events.count_events_by_type(@from, @to, account.id) == %{
             "delivered" => 1,
             "failed" => 1
           }
  end

  test "event_volume/4 counts per hour and fills empty hours" do
    event(event: "delivered", timestamp: ~N[2026-10-26 09:05:00])
    event(event: "delivered", timestamp: ~N[2026-10-26 09:55:00])
    event(event: "failed", timestamp: ~N[2026-10-26 11:30:00])

    assert Events.event_volume(@from, @to, "hour", nil) == [
             %{at: ~N[2026-10-26 08:00:00], counts: %{}},
             %{at: ~N[2026-10-26 09:00:00], counts: %{"delivered" => 2}},
             %{at: ~N[2026-10-26 10:00:00], counts: %{}},
             %{at: ~N[2026-10-26 11:00:00], counts: %{"failed" => 1}}
           ]
  end

  test "event_volume/4 counts per day" do
    event(event: "opened", timestamp: ~N[2026-10-24 10:00:00])
    event(event: "opened", timestamp: ~N[2026-10-26 10:00:00])

    assert Events.event_volume(~N[2026-10-24 06:00:00], @to, "day", nil) == [
             %{at: ~N[2026-10-24 00:00:00], counts: %{"opened" => 1}},
             %{at: ~N[2026-10-25 00:00:00], counts: %{}},
             %{at: ~N[2026-10-26 00:00:00], counts: %{"opened" => 1}}
           ]
  end

  test "top_failure_reasons/4 groups failed events by reason" do
    failed("mailbox full", "a@gmail.com")
    failed("mailbox full", "b@gmail.com")
    failed("no such user", "c@outlook.com")
    event(event: "failed", raw: %{})
    event(event: "delivered", raw: %{"delivery-status" => %{"message" => "OK"}})

    assert Events.top_failure_reasons(@from, @to, nil, 10) == [
             {"mailbox full", 2},
             {"(no reason)", 1},
             {"no such user", 1}
           ]
  end

  test "top_failing_domains/4 groups failed events by recipient domain" do
    failed("x", "a@gmail.com")
    failed("x", "b@Gmail.com")
    failed("x", "c@outlook.com")
    event(event: "delivered", recipient: "d@yahoo.com")

    assert Events.top_failing_domains(@from, @to, nil, 10) == [
             {"gmail.com", 2},
             {"outlook.com", 1}
           ]
  end
end
