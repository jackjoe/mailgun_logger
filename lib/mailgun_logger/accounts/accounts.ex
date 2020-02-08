defmodule MailgunLogger.Accounts do
  @moduledoc false

  import Ecto.Query, warn: false

  alias MailgunLogger.Account
  alias MailgunLogger.Repo

  @spec list_accounts() :: [Account.t()]
  def list_accounts() do
    Repo.all(Account)
  end

  @spec list_active_accounts() :: [Account.t()]
  def list_active_accounts() do
    from(
      a in Account,
      where: a.is_active == true
    )
    |> Repo.all()
  end

  @spec get_account_by_id(integer) :: Account.t()
  def get_account_by_id(id) do
    Repo.get(Account, id)
  end

  @spec create_account(map) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def create_account(params) do
    %Account{}
    |> Account.changeset(params)
    |> Repo.insert()
  end

  @spec update_account(Account.t(), map) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def update_account(account, params) do
    account
    |> Account.changeset(params)
    |> Repo.update()
  end

  @spec delete_account(Account.t()) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def delete_account(%Account{} = account) do
    Repo.delete(account)
  end
end
