defmodule MailgunLoggerWeb.CoreComponentsTest do
  use ExUnit.Case, async: true

  import MailgunLoggerWeb.CoreComponents

  @now ~U[2026-10-26 12:00:00Z]

  test "relative time" do
    assert time_ago(~U[2026-10-26 11:59:30Z], @now) == "just now"
    assert time_ago(~U[2026-10-26 11:59:00Z], @now) == "1 min ago"
    assert time_ago(~U[2026-10-26 11:15:00Z], @now) == "45 min ago"
    assert time_ago(~U[2026-10-26 11:00:00Z], @now) == "1 hour ago"
    assert time_ago(~U[2026-10-26 07:00:00Z], @now) == "5 hours ago"
    assert time_ago(~U[2026-10-25 12:00:00Z], @now) == "1 day ago"
    assert time_ago(~U[2026-10-20 12:00:00Z], @now) == "6 days ago"
  end

  test "relative time accepts a naive UTC timestamp" do
    assert time_ago(~N[2026-10-26 11:00:00], @now) == "1 hour ago"
  end

  test "masks an API key" do
    assert mask_key("key-0123456789abcd") == "••••abcd"
    assert mask_key("abc") == "••••"
    assert mask_key(nil) == ""
  end
end
