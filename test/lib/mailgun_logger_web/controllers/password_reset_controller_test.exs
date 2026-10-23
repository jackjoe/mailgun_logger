defmodule MailgunLoggerWeb.PasswordResetControllerTest do
  use MailgunLoggerWeb.ConnCase

  alias MailgunLogger.Repo
  alias MailgunLogger.User
  alias MailgunLogger.Users

  test "shows the request form", %{conn: conn} do
    conn = get(conn, ~p"/password-reset/request")
    html = html_response(conn, 200)
    assert headings(html) == ["Password forgot"]
    assert html =~ ~s(name="password_reset[email]")
  end

  test "shows the request done page", %{conn: conn} do
    conn = get(conn, ~p"/password-reset/request/done")
    assert headings(html_response(conn, 200)) == ["Password forgot"]
  end

  test "shows the reset done page", %{conn: conn} do
    conn = get(conn, ~p"/password-reset/reset/done")
    assert headings(html_response(conn, 200)) == ["Password forgot"]
  end

  test "shows the reset error page", %{conn: conn} do
    conn = get(conn, ~p"/password-reset/reset/error")
    html = html_response(conn, 200)
    assert headings(html) == ["Password forgot"]
    assert html =~ ~s(href="/password-reset/request")
    assert html =~ ~s(href="/login")
  end

  describe "reset_new" do
    test "shows the reset form for a valid token", %{conn: conn} do
      user = insert(:user, reset_token: "valid-token")
      conn = get(conn, ~p"/password-reset/reset/#{user.reset_token}")
      html = html_response(conn, 200)
      assert headings(html) == ["Password forgot"]
      assert html =~ ~s(action="/password-reset/reset/valid-token")
    end

    test "redirects to the error page for an unknown token", %{conn: conn} do
      conn = get(conn, ~p"/password-reset/reset/unknown-token")
      assert redirected_to(conn) == ~p"/password-reset/reset/error"
    end
  end

  describe "reset_create" do
    test "sets the new password", %{conn: conn} do
      user = insert(:user, reset_token: "valid-token")
      params = %{"password" => "new-password", "password_confirmation" => "new-password"}

      conn = post(conn, ~p"/password-reset/reset/valid-token", %{"user" => params})

      assert redirected_to(conn) == ~p"/password-reset/reset/done"
      assert {:ok, _} = Users.authenticate(user.email, "new-password")
      assert Repo.get!(User, user.id).reset_token == nil
    end

    test "shows an error when the passwords do not match", %{conn: conn} do
      insert(:user, reset_token: "valid-token")
      params = %{"password" => "new-password", "password_confirmation" => "other-password"}

      conn = post(conn, ~p"/password-reset/reset/valid-token", %{"user" => params})

      html = html_response(conn, 200)
      assert html =~ "We could not reset your password."
      assert html =~ "does not match confirmation"
    end

    test "redirects to the error page for an unknown token", %{conn: conn} do
      params = %{"password" => "new-password", "password_confirmation" => "new-password"}
      conn = post(conn, ~p"/password-reset/reset/unknown-token", %{"user" => params})
      assert redirected_to(conn) == ~p"/password-reset/reset/error"
    end
  end

  describe "request_create" do
    test "sends a reset email to a known user", %{conn: conn} do
      user = insert(:user)

      conn =
        post(conn, ~p"/password-reset/request", %{"password_reset" => %{"email" => user.email}})

      assert redirected_to(conn) == ~p"/password-reset/request/done"
      assert_receive {:email, %Swoosh.Email{} = email}

      reset_token = Repo.get!(User, user.id).reset_token
      assert [{_name, address}] = email.to
      assert address == user.email
      assert email.subject == "Reset your password"
      assert email.text_body =~ "/password-reset/reset/#{reset_token}"
    end

    test "sends no email to an unknown address", %{conn: conn} do
      conn =
        post(conn, ~p"/password-reset/request", %{
          "password_reset" => %{"email" => "nobody@example.com"}
        })

      assert redirected_to(conn) == ~p"/password-reset/request/done"
      refute_receive {:email, _}
    end
  end
end
