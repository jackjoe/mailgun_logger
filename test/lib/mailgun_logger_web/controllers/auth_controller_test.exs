defmodule MailgunLoggerWeb.AuthControllerTest do
  use MailgunLoggerWeb.ConnCase

  test "shows the login form", %{conn: conn} do
    insert(:user)
    conn = get(conn, ~p"/login")
    html = html_response(conn, 200)
    assert headings(html) == ["Log in"]
    assert html =~ ~r{<button[^>]*>\s*Log in\s*</button>}
  end

  test "signs in with valid credentials", %{conn: conn} do
    user = insert(:user)
    conn = post(conn, ~p"/login", %{"user" => %{"email" => user.email, "password" => "password"}})
    assert redirected_to(conn) == ~p"/events"
    assert get_session(conn, :current_user_id) == user.id
  end

  test "shows an error with invalid credentials", %{conn: conn} do
    user = insert(:user)
    conn = post(conn, ~p"/login", %{"user" => %{"email" => user.email, "password" => "wrong"}})
    html = html_response(conn, 200)
    assert html =~ "Invalid email or password"
    assert html =~ ~s(value="#{user.email}")
    refute html =~ ~s(value="wrong")
    refute get_session(conn, :current_user_id)
  end

  test "signs out", %{conn: conn} do
    %{conn: conn} = log_in_user(%{conn: conn})
    conn = get(conn, ~p"/logout")
    assert redirected_to(conn) == ~p"/"
    refute get_session(conn, :current_user_id)

    conn = conn |> recycle() |> get(~p"/login")
    flash = conn |> html_response(200) |> LazyHTML.from_document() |> LazyHTML.query(".alert")
    assert Enum.count(flash) == 1
    assert flash |> LazyHTML.text() |> String.trim() == "Signed out"
    assert LazyHTML.attribute(flash, "class") == ["alert alert-info"]
  end

  test "redirects to the login form without a session", %{conn: conn} do
    insert(:user)
    conn = get(conn, ~p"/events")
    assert redirected_to(conn) == ~p"/login"
  end
end
