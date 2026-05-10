defmodule MailgunLogger.RolesTest do
  use MailgunLogger.DataCase

  alias MailgunLogger.Roles

  describe "can?/2 for :manage_roles" do
    test "admin can manage_roles" do
      user = insert(:user, roles: [build(:role, name: "admin")])
      assert Roles.can?(user, :manage_roles)
    end

    test "superuser can manage_roles" do
      user = insert(:user, roles: [build(:role, name: "superuser")])
      assert Roles.can?(user, :manage_roles)
    end

    test "member cannot manage_roles" do
      user = insert(:user, roles: [build(:role, name: "member")])
      refute Roles.can?(user, :manage_roles)
    end

    test "user with no roles cannot manage_roles" do
      user = insert(:user, roles: [])
      refute Roles.can?(user, :manage_roles)
    end
  end
end
