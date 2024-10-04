defmodule MailgunLogger.UserTest do
  use MailgunLogger.DataCase
  use MailgunLoggerWeb.ConnCase

  alias MailgunLogger.User

  alias MailgunLogger.UserFixtures

  @valid_attrs %{
    email: "john.doe@acme.com",
    password: "password",
    client_group_id: nil
  }

  test "validates required fields" do
    changeset = User.changeset(%User{}, %{})
    refute changeset.valid?
    assert "can't be blank" in errors_on(changeset).email
    assert "can't be blank" in errors_on(changeset).password
  end

  test "validates email" do
    changeset = User.changeset(%User{}, %{@valid_attrs | email: "foo"})
    assert "has invalid format" in errors_on(changeset).email
  end

  test "validates email uniqueness" do
    user = insert(:user)
    changeset = User.changeset(%User{}, %{@valid_attrs | email: user.email})
    assert changeset.valid?
    {:error, changeset} = Repo.insert(changeset)
    refute changeset.valid?
    assert "has already been taken" in errors_on(changeset).email
  end

  test "admins can view the 'users' page", %{conn: conn} do
    admin = UserFixtures.admin_user_fixture()

    conn =
      conn
      |> init_test_session(current_user: admin, signed_in: true)
      |> MailgunLoggerWeb.Plugs.Auth.sign_in(admin)

    conn =
      get(conn, ~p"/users")

    assert html_response(conn, 200) =~ "<h1>Users</h1>"
  end

  test "admins can change another user's role from member to admin", %{conn: conn} do
    admin = UserFixtures.admin_user_fixture()
    member = UserFixtures.member_user_fixture()

    conn =
      conn
      |> init_test_session(current_user: admin, signed_in: true)
      |> MailgunLoggerWeb.Plugs.Auth.sign_in(admin)

    patch(conn, ~p"/users/#{member.id}", %{
      "id" => 2,
      "user" => %{},
      "user_role_names" => %{"admin" => "admin"}
    })

    updated_member = MailgunLogger.Users.get_user!(member.id)

    # Assert user has admin role
    assert Enum.any?(updated_member.roles, fn %MailgunLogger.Role{} = role ->
             role.name == "admin"
           end)

    # Assert user does not have member role anymore
    assert Enum.any?(updated_member.roles, fn %MailgunLogger.Role{} = role ->
             role.name != "member"
           end)
  end
end
