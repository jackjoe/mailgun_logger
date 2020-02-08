defmodule MailgunLoggerWeb.Plugs.Auth do
  import Plug.Conn
  import Phoenix.Controller

  alias MailgunLoggerWeb.Router.Helpers, as: Routes
  alias MailgunLogger.Users

  @moduledoc """
  Plug to enforce authentication. When called by a pipeline, the plug will try to find a truthy `signed_in` boolean on the conn. When present it continues, otherwise the conn is halted and redirected to the login form.

  The Plug also contains methods to provide sign in and sign out. These are typically called from the auth controller.
  """

  @spec init(any) :: any
  def init(opts), do: opts

  @spec call(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def call(conn, _) do
    with user_id when not is_nil(user_id) <- get_session(conn, :current_user_id),
         user when not is_nil(user) <- Users.get_user(user_id) do
      conn
      |> assign(:current_user, user)
      |> assign(:signed_in?, true)
    else
      _ ->
        conn
        |> assign(:current_user, nil)
        |> assign(:signed_in?, false)
        |> redirect(to: Routes.auth_path(conn, :new))
    end
  end

  @doc """
  Signs in a user resource.
  Puts the user on the conn (`current_user`) and also a boolean to facilitate easy logged in checks.
  """
  @spec sign_in(Plug.Conn.t(), User.t()) :: Plug.Conn.t()
  def sign_in(conn, user) do
    put_session(conn, :current_user_id, user.id)
  end

  @doc "Sign out a user"
  @spec sign_out(Plug.Conn.t()) :: Plug.Conn.t()
  def sign_out(conn) do
    conn
    |> clear_session()
    |> configure_session(drop: true)
  end
end
