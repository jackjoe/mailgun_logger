defmodule MailgunLogger.UsersTest do
  use MailgunLogger.DataCase

  alias MailgunLogger.Users

  describe "create_user_with_roles/2" do
    test "creates user with assigned roles atomically" do
      admin_role = insert(:role, name: "admin")

      {:ok, user} =
        Users.create_user_with_roles(
          %{email: "new@example.com", password: "password123"},
          [admin_role]
        )

      assert Enum.map(user.roles, & &1.name) == ["admin"]
    end

    test "creates user with no roles when given empty list" do
      {:ok, user} =
        Users.create_user_with_roles(
          %{email: "norole@example.com", password: "password123"},
          []
        )

      assert user.roles == []
    end
  end

  describe "update_user_with_roles/3" do
    test "replaces existing roles atomically" do
      member_role = insert(:role, name: "member")
      admin_role = insert(:role, name: "admin")
      user = insert(:user, roles: [member_role])

      {:ok, updated} = Users.update_user_with_roles(user, %{}, [admin_role])

      assert Enum.map(updated.roles, & &1.name) == ["admin"]
    end

    test "removes all roles when given empty list" do
      admin_role = insert(:role, name: "admin")
      user = insert(:user, roles: [admin_role])

      {:ok, updated} = Users.update_user_with_roles(user, %{}, [])

      assert updated.roles == []
    end

    test "assigns multiple roles at once" do
      member_role = insert(:role, name: "member")
      admin_role = insert(:role, name: "admin")
      user = insert(:user, roles: [])

      {:ok, updated} = Users.update_user_with_roles(user, %{}, [member_role, admin_role])

      role_names = Enum.map(updated.roles, & &1.name) |> Enum.sort()
      assert role_names == ["admin", "member"]
    end

    test "returns error and makes no changes when profile update fails" do
      admin_role = insert(:role, name: "admin")
      user = insert(:user, roles: [admin_role])
      other_user = insert(:user, roles: [])

      assert {:error, _changeset} =
               Users.update_user_with_roles(user, %{email: other_user.email}, [])

      # roles unchanged
      reloaded = Users.get_user!(user.id)
      assert Enum.map(reloaded.roles, & &1.name) == ["admin"]
    end
  end
end
