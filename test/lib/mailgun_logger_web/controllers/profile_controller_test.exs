defmodule MailgunLoggerWeb.ProfileControllerTest do
  use MailgunLoggerWeb.ConnCase

  alias MailgunLogger.Users

  setup :log_in_user

  test "shows the profile form", %{conn: conn, user: user} do
    conn = get(conn, ~p"/profile")
    html = html_response(conn, 200)
    assert headings(html) == ["Profile"]
    assert html =~ ~s(value="#{user.email}")
  end

  test "updates the profile", %{conn: conn, user: user} do
    conn = put(conn, ~p"/profile", %{"user" => %{"theme" => "light"}})
    assert redirected_to(conn) == ~p"/profile"
    assert Users.get_user!(user.id).theme == "light"

    conn = conn |> recycle() |> get(~p"/profile")
    html = html_response(conn, 200)
    assert html =~ "Profile updated."
    assert html =~ ~s(data-theme="light")
  end

  test "shows errors for an invalid profile", %{conn: conn} do
    conn = put(conn, ~p"/profile", %{"user" => %{"email" => "invalid"}})
    assert html_response(conn, 200) =~ "has invalid format"
  end
end
