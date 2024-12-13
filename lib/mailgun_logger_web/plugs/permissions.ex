defmodule MailgunLoggerWeb.Plugs.Permissions do
  import Plug.Conn
  import Phoenix.Controller
  alias MailgunLogger.Roles

  @moduledoc """
  Plug to enforce role based permissions. When called by a pipeline, the plug will try to determine the permission based on the connection info and compare it to the permissions of the logged in user's roles.

  The Plug contains private methods for each of these steps.
  """
  @spec init(any) :: any
  def init(opts), do: opts

  @spec call(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def call(conn, _) do
    permission = determine_permission(conn)
    IO.puts """
    PERMISSION: #{permission}
    """
    check_permission(conn, permission)
  end

  @spec determine_permission(Plug.Conn.t()) :: String.t()
  defp determine_permission(conn) do


    method=conn.method
    path=conn.request_path

    cond do
      method == "GET" && path == "/" -> "view_home"
      method == "GET" && path == "/events" -> "view_events"
      method == "GET" && String.match?(path, ~r/events\/[[:digit:]]+$/) -> "view_events_detail"
      method == "GET" && String.match?(path, ~r/events\/[[:digit:]]+\/stored_message$/) -> "view_events_detail_stored_message"
      method == "GET" && path == "/stats" -> "view_stats"
      method == "GET" && path == "/accounts" -> "view_accounts"
      method in ["GET","PUT"] && String.match?(path, ~r/accounts\/[[:digit:]]+/) -> "edit_accounts"
      method == "DELETE" && String.match?(path, ~r/accounts\/[[:digit:]]+/) -> "delete_accounts"
      method == "GET" && path == "/accounts/new" -> "create_accounts"
      method =="POST" && path == "/accounts" -> "create_accounts"
      method == "GET" && path == "/users" -> "view_users"
      method in ["GET","PUT"] && String.match?(path, ~r/users\/[[:digit:]]+/) -> "edit_users"
      method == "DELETE" && String.match?(path, ~r/users\/[[:digit:]]+/) -> "delete_users"
      method == "GET" && path == "/users/new" -> "create_users"
      method =="POST" && path == "/users" -> "create_users"
      true -> "undefined_permission"
    end
  end

  @spec check_permission(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  defp check_permission(conn, permission) do
    if Roles.can?(conn.assigns[:current_user], String.to_atom(permission)) do
      IO.puts "allowed"
      conn
    else
        IO.puts "denied"
        IO.puts"""
        #{Roles.abilities(conn.assigns[:current_user])}
        """
        conn
        |> put_status(403)
        |> render(MailgunLoggerWeb.ErrorView, "403.html")
        |> halt()
    end
  end
end
