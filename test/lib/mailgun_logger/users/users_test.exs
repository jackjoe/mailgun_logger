defmodule MailgunLogger.UsersTest do
  use MailgunLogger.DataCase

  alias MailgunLogger.Users
  alias MailgunLogger.User

  defp insert_role(name), do: insert(:role, name: name)

  defp insert_user_with_roles(roles) do
    %User{}
    |> User.changeset(%{
      email: "user#{System.unique_integer()}@example.com",
      password: "password",
      firstname: "Test",
      lastname: "User",
      theme: "system"
    })
    |> Ecto.Changeset.put_assoc(:roles, roles)
    |> Repo.insert!()
    |> Repo.preload(:roles)
  end

  test "create_user assigns selected roles" do
    admin = insert_role("admin")
    member = insert_role("member")

    params = %{
      "email" => "new@example.com",
      "password" => "password",
      "firstname" => "New",
      "lastname" => "User",
      "theme" => "system",
      "role_ids" => [to_string(admin.id), to_string(member.id)]
    }

    assert {:ok, user} = Users.create_user(params)
    user = Repo.preload(user, :roles)

    assert Enum.sort(Enum.map(user.roles, & &1.name)) == ["admin", "member"]
  end

  test "update_user changes a user's roles" do
    admin = insert_role("admin")
    member = insert_role("member")

    actor = insert_user_with_roles([admin])
    user = insert_user_with_roles([admin])

    params = %{
      "email" => user.email,
      "firstname" => user.firstname,
      "lastname" => user.lastname,
      "theme" => user.theme,
      "role_ids" => [to_string(member.id)]
    }

    assert {:ok, updated_user} = Users.update_user(actor, user, params)
    updated_user = Repo.preload(updated_user, :roles)

    assert Enum.map(updated_user.roles, & &1.name) == ["member"]
  end

  test "update_user prevents self downgrade when manage_users access would be removed" do
    admin = insert_role("admin")
    member = insert_role("member")

    actor = insert_user_with_roles([admin])

    params = %{
      "email" => actor.email,
      "firstname" => actor.firstname,
      "lastname" => actor.lastname,
      "theme" => actor.theme,
      "role_ids" => [to_string(member.id)]
    }

    assert {:error, changeset} = Users.update_user(actor, actor, params)
    assert "You cannot remove your own user management access." in errors_on(changeset).roles

    reloaded_actor = Users.get_user!(actor.id)
    assert Enum.map(reloaded_actor.roles, & &1.name) == ["admin"]
  end

  test "update_user allows changing another user's roles" do
    admin = insert_role("admin")
    member = insert_role("member")

    actor = insert_user_with_roles([admin])
    other_user = insert_user_with_roles([admin])

    params = %{
      "email" => other_user.email,
      "firstname" => other_user.firstname,
      "lastname" => other_user.lastname,
      "theme" => other_user.theme,
      "role_ids" => [to_string(member.id)]
    }

    assert {:ok, updated_user} = Users.update_user(actor, other_user, params)
    updated_user = Repo.preload(updated_user, :roles)

    assert Enum.map(updated_user.roles, & &1.name) == ["member"]
  end
end
