defmodule MailgunLogger.RolesTest do
  use MailgunLogger.DataCase

  alias MailgunLogger.Roles
  alias MailgunLogger.User

  defp user_with_roles(id, roles) do
    %User{
      id: id,
      roles: Enum.map(roles, &%{name: &1})
    }
  end

  test "returns false when user tries to modify themselves" do
    user = user_with_roles(1, ["admin"])

    refute Roles.can_modify_roles?(user, user)
  end

  test "returns true when user has assign_roles permission" do
    user = user_with_roles(1, ["admin"])
    target = user_with_roles(2, ["member"])

    assert Roles.can_modify_roles?(user, target)
  end

  test "returns true when user has manage_admins permission" do
    user = user_with_roles(1, ["superuser"])
    target = user_with_roles(2, ["admin"])

    assert Roles.can_modify_roles?(user, target)
  end

  test "returns false when user has no relevant roles" do
    user = user_with_roles(1, ["member"])
    target = user_with_roles(2, ["member"])

    refute Roles.can_modify_roles?(user, target)
  end

  test "returns false when user has no roles" do
    user = %User{id: 1, roles: []}
    target = %User{id: 2, roles: [%{name: "member"}]}
    refute Roles.can_modify_roles?(user, target)
  end
end
