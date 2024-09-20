defmodule MailgunLogger.Seeder do
  @moduledoc false

  alias MailgunLogger.Repo
  alias MailgunLogger.Role

  # alias MailgunLogger.UserRole

  @roles [%Role{name: "superuser"}, %Role{name: "admin"}, %Role{name: "member"}]

  def run do
    Enum.each(@roles, &insert_if_new(&1))
  end

  defp exists(%Role{} = role), do: Repo.get_by(Role, name: role.name)

  defp insert_if_new(model) do
    if !exists(model) do
      Repo.insert!(model)
    end
  end

  # Bind roles and users (default)
  # defp bind_role(role_name, user) do
  #   if !has_role(role_name, user.id) do
  #     changeset =
  #       UserRole.changeset(
  #         %UserRole{},
  #         %{
  #           role_id: Repo.get_by!(Role, name: role_name).id,
  #           user_id: Repo.get!(User, user.id).id
  #         }
  #       )
  #
  #     Repo.insert!(changeset)
  #   end
  #
  #   user
  # end

  # defp has_role(role_name, user_id) do
  #   Repo.get_by(UserRole, role_id: role_name_to_id(role_name), user_id: user_id)
  # end
  #
  # defp role_name_to_id(role_name) do
  #   Repo.get_by!(Role, name: role_name).id
  # end
end
