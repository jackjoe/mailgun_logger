defmodule MailgunLoggerWeb.UserControllerTest do
  use MailgunLoggerWeb.ConnCase

  alias MailgunLogger.{Repo, Role, User, Users}

  setup do
    ensure_role!("admin")
    ensure_role!("superuser")
    ensure_role!("member")
    :ok
  end

  test "admin can edit another user's roles", %{conn: conn} do
    admin = user_with_roles(["admin"])
    target = user_with_roles(["member"])

    conn = login(conn, admin)

    params = %{
      "firstname" => "Updated",
      "current_roles" => %{
        "member" => "false",
        "admin" => "true",
        "superuser" => "false"
      }
    }
    conn = put(conn, Routes.user_path(conn, :update, target.id), %{"user" => params})

    assert redirected_to(conn) == Routes.user_path(conn, :index)

    updated = reload_user!(target.id)
    assert role_names(updated) == ["admin"]
    assert updated.firstname == "Updated"
  end

  test "superuser can edit another user's roles", %{conn: conn} do
    superuser = user_with_roles(["superuser"])
    target = user_with_roles(["member"])

    conn = login(conn, superuser)

    params = %{
      "firstname" => "Updated",
      "current_roles" => %{
        "member" => "false",
        "admin" => "true",
        "superuser" => "false"
      }
    }
    conn = put(conn, Routes.user_path(conn, :update, target.id), %{"user" => params})

    assert redirected_to(conn) == Routes.user_path(conn, :index)

    updated = reload_user!(target.id)
    assert role_names(updated) == ["admin"]
    assert updated.firstname == "Updated"
  end

  test "admin cannot edit own roles", %{conn: conn} do
    admin = user_with_roles(["admin"])

    conn = login(conn, admin)

    params = %{
      "firstname" => "Updated",
      "current_roles" => %{
        "member" => "true",
        "admin" => "false",
        "superuser" => "false"
      }
    }
    conn = put(conn, Routes.user_path(conn, :update, admin.id), %{"user" => params})

    assert redirected_to(conn) == Routes.user_path(conn, :index)

    updated = reload_user!(admin.id)
    assert role_names(updated) == ["admin"]
    assert role_names(updated) != ["member"]
    assert updated.firstname == "Updated"
  end

  test "superuser cannot edit own roles", %{conn: conn} do
    superuser = user_with_roles(["superuser"])

    conn = login(conn, superuser)

    params = %{
      "firstname" => "Updated",
      "current_roles" => %{
        "member" => "true",
        "admin" => "false",
        "superuser" => "false"
      }
    }
    conn = put(conn, Routes.user_path(conn, :update, superuser.id), %{"user" => params})

    assert redirected_to(conn) == Routes.user_path(conn, :index)

    updated = reload_user!(superuser.id)
    assert role_names(updated) == ["superuser"]
    assert role_names(updated) != ["member"]
    assert updated.firstname == "Updated"
  end


  # --- helpers ---
  defp login(conn, %User{id: id}) do
    conn
    |> init_test_session(%{})
    |> put_session(:current_user_id, id)
  end

  defp user_with_roles(role_names) do
    user = insert(:user)
    roles = Enum.map(role_names, &ensure_role!/1)
    user
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:roles, roles)
    |> Repo.update!()
  end

  defp ensure_role!(name) do
    Repo.get_by(Role, name: name) || Repo.insert!(%Role{name: name})
  end

  defp reload_user!(id), do: Users.get_user!(id)

  defp role_names(user), do: user.roles |> Enum.map(& &1.name) |> Enum.sort()
end
