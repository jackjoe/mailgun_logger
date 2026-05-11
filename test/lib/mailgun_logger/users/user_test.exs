defmodule MailgunLogger.UserTest do
  use MailgunLogger.DataCase

  alias MailgunLogger.User
  # alias MailgunLogger.Role

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

  # Test update role
  test "updates role when role_id changes" do
    user = insert(:user)
    admin_role = Repo.insert!(%Role{name: "admin"})

    changeset = User.update_changeset(user, %{"role_id" => admin_role.id})
    assert changeset.valid?
    assert get_change(changeset, :roles) == [admin_role]
  end
end
