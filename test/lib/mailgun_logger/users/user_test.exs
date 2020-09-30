defmodule MailgunLogger.UserTest do
  use MailgunLogger.DataCase

  alias MailgunLogger.User

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
end
