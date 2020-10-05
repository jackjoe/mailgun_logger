defmodule MailgunLoggerWeb.PasswordResetController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.User
  alias MailgunLogger.Users

  def request_new(conn, _params) do
    render(conn, :request_new)
  end

  def request_create(conn, %{"password_reset" => %{"email" => email}}) do
    case Users.gen_password_reset_token(email) do
      {:ok, user} ->
        user
        |> MailgunLogger.Emails.reset_password(conn)
        |> MailgunLogger.Mailer.deliver_it_later()

      {_, _} ->
        {:error}
    end

    redirect(conn, to: Routes.password_reset_path(conn, :request_done))
  end

  def request_done(conn, _params) do
    render(conn, :request_done)
  end

  def reset_new(conn, %{"reset_token" => reset_token}) do
    changeset = User.password_forgot_changeset(%User{}, %{reset_token: reset_token})

    case Users.get_user_by_reset_token(reset_token) do
      nil -> redirect(conn, to: Routes.password_reset_path(conn, :reset_error))
      _ -> render(conn, :reset_new, changeset: changeset, reset_token: reset_token)
    end
  end

  def reset_create(conn, %{"reset_token" => reset_token, "user" => user_params}) do
    case Users.get_user_by_reset_token(reset_token) do
      nil ->
        redirect(conn, to: Routes.password_reset_path(conn, :reset_error, reset_token))

      user ->
        case Users.reset_password(user, user_params) do
          {:ok, _user} ->
            conn
            |> redirect(to: Routes.password_reset_path(conn, :reset_done))

          {:error, changeset} ->
            conn
            |> put_flash(:error, gettext("We could not reset your password."))
            |> render(:reset_new, changeset: changeset, reset_token: reset_token)
        end
    end
  end

  def reset_done(conn, _params) do
    render(conn, :reset_done)
  end

  def reset_error(conn, _params) do
    render(conn, :reset_error)
  end
end
