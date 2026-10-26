defmodule MailgunLoggerWeb.PageControllerTest do
  use MailgunLoggerWeb.ConnCase

  setup :log_in_user

  test "redirects the home page to the events", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/events"
  end

  test "starts a run and says so", %{conn: conn} do
    conn = post(conn, ~p"/trigger-run")

    # Wait for the run, so it does not use the database after the test ends.
    if pid = Process.whereis(:run_task) do
      ref = Process.monitor(pid)
      assert_receive {:DOWN, ^ref, :process, ^pid, _reason}
    end

    assert redirected_to(conn) == ~p"/events"
    assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Run started"
  end

  describe "stats" do
    defp hours_ago(hours) do
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(-hours * 3600)
      |> NaiveDateTime.truncate(:second)
    end

    defp tile(html, label) do
      html
      |> LazyHTML.from_document()
      |> LazyHTML.query(".stat-tile")
      |> Enum.find(&(&1 |> LazyHTML.query(".stat-label") |> LazyHTML.text() =~ label))
    end

    defp text(node), do: node |> LazyHTML.text() |> String.split() |> Enum.join(" ")

    test "shows counts and rates for the last 24 hours", %{conn: conn} do
      for _ <- 1..4, do: insert(:event, event: "accepted", timestamp: hours_ago(1))
      for _ <- 1..3, do: insert(:event, event: "delivered", timestamp: hours_ago(2))
      insert(:event, event: "failed", timestamp: hours_ago(3))
      insert(:event, event: "delivered", timestamp: hours_ago(30))

      html = conn |> get(~p"/stats") |> html_response(200)

      assert headings(html) |> hd() == "Stats"
      assert text(tile(html, "Accepted")) =~ "4"
      assert text(tile(html, "Delivered")) =~ "3 75.0% of accepted"
      assert text(tile(html, "Failed")) =~ "1 25.0% of accepted"
      assert html =~ ~s(<a href="/stats?range=24h" class="is-active">)
    end

    test "compares with the previous period", %{conn: conn} do
      insert(:event, event: "delivered", timestamp: hours_ago(1))
      insert(:event, event: "delivered", timestamp: hours_ago(2))
      insert(:event, event: "delivered", timestamp: hours_ago(30))

      html = conn |> get(~p"/stats") |> html_response(200)
      assert text(tile(html, "Delivered")) =~ "+100% vs previous 24h"
    end

    test "uses the selected range and account", %{conn: conn} do
      account = insert(:account)
      insert(:event, event: "delivered", account: account, timestamp: hours_ago(48))
      insert(:event, event: "delivered", timestamp: hours_ago(48))

      html = conn |> get(~p"/stats?range=7d&account_id=#{account.id}") |> html_response(200)

      assert text(tile(html, "Delivered")) =~ "1"
      assert html =~ ~s(<a href="/stats?range=7d&amp;account_id=#{account.id}" class="is-active">)
    end

    test "links a tile to the matching events", %{conn: conn} do
      html = conn |> get(~p"/stats") |> html_response(200)
      [href] = html |> tile("Failed") |> LazyHTML.query("a") |> LazyHTML.attribute("href")

      query = href |> URI.parse() |> Map.fetch!(:query) |> Plug.Conn.Query.decode()
      filters = Map.values(query["filters"])

      assert %{"field" => "event", "op" => "==", "value" => "failed"} in filters
      assert Enum.any?(filters, &match?(%{"field" => "timestamp", "op" => ">="}, &1))
      assert Enum.any?(filters, &match?(%{"field" => "timestamp", "op" => "<="}, &1))
    end

    test "shows the failure reasons and failing domains", %{conn: conn} do
      insert(:event,
        event: "failed",
        recipient: "a@gmail.com",
        timestamp: hours_ago(1),
        raw: %{"delivery-status" => %{"message" => "mailbox full"}}
      )

      html = conn |> get(~p"/stats") |> html_response(200)
      assert html =~ "mailbox full"
      assert html =~ "gmail.com"
    end

    test "draws one chart bar per hour", %{conn: conn} do
      insert(:event, event: "delivered", timestamp: hours_ago(1))

      bars =
        conn
        |> get(~p"/stats")
        |> html_response(200)
        |> LazyHTML.from_document()
        |> LazyHTML.query("svg.volume-chart .bar")

      assert Enum.count(bars) in 24..25
    end

    test "shows the health of each account", %{conn: conn} do
      insert(:account,
        domain: "broken.example.com",
        last_run_at: DateTime.utc_now(),
        last_run_status: "error",
        last_run_error: "401: unauthorized"
      )

      html = conn |> get(~p"/stats") |> html_response(200)
      assert html =~ "broken.example.com"
      assert html =~ "401: unauthorized"
    end
  end

  test "redirects the old graphs page to the stats", %{conn: conn} do
    assert conn |> get(~p"/graphs") |> redirected_to() == ~p"/stats"
  end

  test "shows the non-affiliation notice", %{conn: conn} do
    conn = get(conn, ~p"/non-affiliation")
    assert headings(html_response(conn, 200)) == ["Notice of Non-Affiliation and Disclaimer"]
  end

  test "renders the not found page", %{conn: conn} do
    conn = get(conn, "/does-not-exist")
    assert html_response(conn, 404) == "Not Found"
  end
end
