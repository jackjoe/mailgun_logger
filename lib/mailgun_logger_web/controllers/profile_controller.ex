defmodule MailgunLoggerWeb.ProfileController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Users
  alias MailgunLogger.User

  defp role_options do
    MailgunLogger.Roles.list_roles()
    |> Enum.map(fn role ->
      {String.capitalize(role.name), role.id}
    end)
  end

  def edit(conn, _) do
    user = conn.assigns.current_user
    current_user = conn.assigns.current_user
    changeset = User.changeset(user)
    selected_role_ids = Enum.map(user.roles, & &1.id)

    conn
    |> put_view(MailgunLoggerWeb.UserView)
    |> render(:profile, changeset: changeset, user: user, current_user: current_user, roles: role_options(), selected_role_ids: selected_role_ids)
  end

  def update(conn, %{"user" => params}) do
    user = conn.assigns.current_user
    current_user = conn.assigns.current_user
    selected_role_ids = Enum.map(user.roles, & &1.id)

    params =
      if MailgunLogger.Roles.can?(current_user, :manage_roles) do
        params
      else
        Map.delete(params, "role_ids")
      end

    case Users.update_user(user, params, user.roles) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Profile updated.")
        |> redirect(to: Routes.profile_path(conn, :edit))

      {:error, changeset} ->
        conn
        |> put_view(MailgunLoggerWeb.UserView)
        |> render(:profile, changeset: changeset, user: user, current_user: current_user, roles: role_options(), selected_role_ids: selected_role_ids)
    end
  end
end
