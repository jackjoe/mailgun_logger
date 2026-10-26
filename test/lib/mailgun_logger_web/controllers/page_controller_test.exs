defmodule MailgunLoggerWeb.PageControllerTest do
  use MailgunLoggerWeb.ConnCase

  setup :log_in_user

  test "redirects the home page to the events", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/events"
  end

  test "starts a run and says so", %{conn: conn} do
    conn = post(conn, ~p"/trigger-run")
    assert redirected_to(conn) == ~p"/events"
    assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Run started"
  end

  test "shows the stats", %{conn: conn} do
    insert(:event, event: "failed")
    conn = get(conn, ~p"/stats")
    html = html_response(conn, 200)
    assert headings(html) == ["Main dashboard", "Some stats"]
    assert html =~ ~r{<dt>Failed:</dt>\s*<dd>1</dd>}
    assert html =~ ~r{<dt>Clicked:</dt>\s*<dd>0</dd>}
    assert html =~ ~r{<a href="/stats" class="is-active">\s*Stats\s*</a>}
  end

  test "shows the graphs", %{conn: conn} do
    conn = get(conn, ~p"/graphs")
    assert html_response(conn, 200) =~ ~s(<canvas id="myChart">)
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
