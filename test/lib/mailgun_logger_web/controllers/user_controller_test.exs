defmodule MailgunLoggerWeb.UserControllerTest do
  use MailgunLoggerWeb.ConnCase

  alias MailgunLogger.Users

  setup :log_in_user

  test "lists the users", %{conn: conn, user: user} do
    conn = get(conn, ~p"/users")
    html = html_response(conn, 200)
    assert headings(html) == ["Users"]
    assert html =~ user.email
    assert html =~ ~s(href="/users/#{user.id}/edit")
  end

  test "shows the new user form", %{conn: conn} do
    conn = get(conn, ~p"/users/new")
    html = html_response(conn, 200)
    assert headings(html) == ["New user"]
    assert html =~ ~s(name="user[password]")
    assert html =~ "First name"
    assert html =~ "Last name"
  end

  test "creates a user", %{conn: conn} do
    params = %{"email" => "new@example.com", "password" => "password", "theme" => "light"}
    conn = post(conn, ~p"/users", %{"user" => params})
    assert redirected_to(conn) == ~p"/users"
    assert Users.get_user_by_email("new@example.com").theme == "light"
  end

  test "shows errors for an invalid user", %{conn: conn} do
    conn = post(conn, ~p"/users", %{"user" => %{"email" => "new", "password" => "password"}})
    assert html_response(conn, 200) =~ "has invalid format"
  end

  test "shows the edit user form", %{conn: conn, user: user} do
    conn = get(conn, ~p"/users/#{user}/edit")
    html = html_response(conn, 200)
    assert headings(html) == ["Edit user"]
    assert html =~ ~s(value="#{user.email}")
    refute html =~ ~s(name="user[password]")
  end

  test "updates a user", %{conn: conn} do
    other = insert(:user)
    conn = put(conn, ~p"/users/#{other}", %{"user" => %{"firstname" => "Jane"}})
    assert redirected_to(conn) == ~p"/users"
    assert Users.get_user!(other.id).firstname == "Jane"
  end

  test "deletes a user", %{conn: conn} do
    other = insert(:user)
    conn = delete(conn, ~p"/users/#{other}")
    assert redirected_to(conn) == ~p"/users"
    refute Users.get_user(other.id)

    conn = conn |> recycle() |> get(~p"/users")
    assert html_response(conn, 200) =~ "user deleted successfully."
  end
end
