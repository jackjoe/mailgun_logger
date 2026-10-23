defmodule MailgunLoggerWeb.PasswordResetControllerTest do
  use MailgunLoggerWeb.ConnCase

  alias MailgunLogger.Repo
  alias MailgunLogger.User

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
