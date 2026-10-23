defmodule MailgunLoggerWeb.SetupControllerTest do
  use MailgunLoggerWeb.ConnCase

  alias MailgunLogger.Users

  test "redirects to the setup page when there are no users", %{conn: conn} do
    conn = get(conn, ~p"/events")
    assert redirected_to(conn) == ~p"/setup"
  end

  test "shows the setup form when there are no users", %{conn: conn} do
    conn = get(conn, ~p"/setup")
    assert headings(html_response(conn, 200)) == ["Welcome newbie!"]
  end

  test "creates the admin user", %{conn: conn} do
    insert(:role, name: "admin")

    conn =
      post(conn, ~p"/setup", %{
        "user" => %{"email" => "admin@example.com", "password" => "password"}
      })

    assert redirected_to(conn) == ~p"/"
    assert [%{email: "admin@example.com", roles: [%{name: "admin"}]}] = Users.list_users()
  end

  test "shows errors for an invalid admin user", %{conn: conn} do
    conn = post(conn, ~p"/setup", %{"user" => %{"email" => "admin", "password" => "short"}})
    assert html_response(conn, 200) =~ "has invalid format"
    refute Users.any_users?()
  end

  test "redirects away when there are users", %{conn: conn} do
    insert(:user)
    conn = get(conn, ~p"/setup")
    assert redirected_to(conn) == ~p"/"
  end
end
