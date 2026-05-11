defmodule MailgunLogger.Roles.RolesTest do
  use MailgunLogger.DataCase

  alias MailgunLogger.Roles

  defp superuser, do: build(:user, roles: [build(:role, name: "superuser")])
  defp admin, do: build(:user, roles: [build(:role, name: "admin")])
  defp member, do: build(:user, roles: [build(:role, name: "member")])

  describe "can?/2 — gate layer (action-level permissions)" do
    test "member: allowed actions" do
      m = member()
      assert Roles.can?(m, :view_profile)
      assert Roles.can?(m, :view_event)
      assert Roles.can?(m, :view_stats)
      assert Roles.can?(m, :view_graphs)
    end

    test "member: forbidden actions (admin/superuser territory)" do
      m = member()
      refute Roles.can?(m, :view_users)
      refute Roles.can?(m, :edit_user)
      refute Roles.can?(m, :create_user)
      refute Roles.can?(m, :delete_user)
      refute Roles.can?(m, :manage_accounts)
      refute Roles.can?(m, :manage_superusers)
      refute Roles.can?(m, :grant_superuser_role)
    end

    test "admin: inherits member actions" do
      a = admin()
      assert Roles.can?(a, :view_profile)
      assert Roles.can?(a, :view_event)
      assert Roles.can?(a, :view_stats)
      assert Roles.can?(a, :view_graphs)
    end

    test "admin: has admin-only actions" do
      a = admin()
      assert Roles.can?(a, :view_users)
      assert Roles.can?(a, :edit_user)
      assert Roles.can?(a, :create_user)
      assert Roles.can?(a, :delete_user)
      assert Roles.can?(a, :manage_accounts)
      assert Roles.can?(a, :manage_admins)
      assert Roles.can?(a, :manage_members)
      assert Roles.can?(a, :grant_admin_role)
      assert Roles.can?(a, :grant_member_role)
    end

    test "admin: cannot touch superuser-only actions" do
      a = admin()
      refute Roles.can?(a, :manage_superusers)
      refute Roles.can?(a, :grant_superuser_role)
    end

    test "superuser: inherits all admin and member actions" do
      s = superuser()
      assert Roles.can?(s, :view_event)
      assert Roles.can?(s, :edit_user)
      assert Roles.can?(s, :manage_admins)
      assert Roles.can?(s, :grant_admin_role)
    end

    test "superuser: has superuser-only actions" do
      s = superuser()
      assert Roles.can?(s, :manage_superusers)
      assert Roles.can?(s, :grant_superuser_role)
    end
  end

  describe "can_manage?/2 — resource layer (who can edit/delete whom)" do
    test "superuser can manage anyone" do
      s = superuser()
      assert Roles.can_manage?(s, superuser())
      assert Roles.can_manage?(s, admin())
      assert Roles.can_manage?(s, member())
    end

    test "admin can manage admins and members, but NOT superusers" do
      a = admin()
      refute Roles.can_manage?(a, superuser())
      assert Roles.can_manage?(a, admin())
      assert Roles.can_manage?(a, member())
    end

    test "member cannot manage anyone" do
      m = member()
      refute Roles.can_manage?(m, superuser())
      refute Roles.can_manage?(m, admin())
      refute Roles.can_manage?(m, member())
    end
  end

  describe "can_grant_role?/2 — resource layer (who can assign which role)" do
    test "superuser can grant any role" do
      s = superuser()
      assert Roles.can_grant_role?(s, "superuser")
      assert Roles.can_grant_role?(s, "admin")
      assert Roles.can_grant_role?(s, "member")
    end

    test "admin can grant admin and member, but NOT superuser" do
      a = admin()
      refute Roles.can_grant_role?(a, "superuser")
      assert Roles.can_grant_role?(a, "admin")
      assert Roles.can_grant_role?(a, "member")
    end

    test "member cannot grant any role" do
      m = member()
      refute Roles.can_grant_role?(m, "superuser")
      refute Roles.can_grant_role?(m, "admin")
      refute Roles.can_grant_role?(m, "member")
    end
  end
end
