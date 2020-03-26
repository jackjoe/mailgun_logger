defmodule MailgunLogger.AccountTest do
  use MailgunLogger.DataCase

  alias MailgunLogger.Account

  @valid_attrs %{
    api_key: "api_key",
    domain: "bol.com"
  }

  test "validates required fields" do
    changeset = Account.changeset(%Account{}, %{})
    refute changeset.valid?
    assert "can't be blank" in errors_on(changeset).api_key
    assert "can't be blank" in errors_on(changeset).domain
  end

  test "validates api_key uniqueness" do
    account = insert(:account)
    changeset = Account.changeset(%Account{}, %{@valid_attrs | api_key: account.api_key})
    assert changeset.valid?
    {:error, changeset} = Repo.insert(changeset)
    refute changeset.valid?
    assert "has already been taken" in errors_on(changeset).api_key
  end
end
