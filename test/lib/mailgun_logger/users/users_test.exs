defmodule MailgunLogger.Users.UsersTest do
  use MailgunLogger.DataCase
  alias MailgunLogger.Users

  describe "count_superusers/0" do
    test "returns 0 when there are no superusers" do
      assert Users.count_superusers() == 0
    end

    test "returns the correct count" do
      superuser_role = insert(:role, name: "superuser")
      admin_role = insert(:role, name: "admin")
      insert(:user, roles: [superuser_role])
      insert(:user, roles: [superuser_role])
      insert(:user, roles: [admin_role])
      assert Users.count_superusers() == 2
    end
  end

  describe "create_user/1" do
    test "creates user with assigned role" do
      admin_role = insert(:role, name: "admin")

      {:ok, user} =
        Users.create_user(%{
          "email" => "juan@gmail.com",
          "password" => "password123456",
          "role_ids" => [admin_role.id]
        })

      user = Repo.preload(user, :roles)
      assert Enum.map(user.roles, & &1.name) == ["admin"]
    end
  end

  describe "update_user/2" do
    test "replaces existing roles atomically" do
      member_role = insert(:role, name: "member")
      admin_role = insert(:role, name: "admin")
      user = insert(:user, roles: [member_role])

      {:ok, updated} = Users.update_user(user, %{"role_ids" => [admin_role.id]})

      updated = Repo.preload(updated, :roles, force: true)
      assert Enum.map(updated.roles, & &1.name) == ["admin"]
    end
  end
end
