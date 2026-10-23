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

  test "the account filter defaults to all accounts", %{conn: conn} do
    html = conn |> get(~p"/events") |> html_response(200)

    options =
      html
      |> LazyHTML.from_document()
      |> LazyHTML.query(~s(select[name="filters[4][value]"] option))
      |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))

    assert hd(options) == "all"
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
