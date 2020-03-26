defmodule MailgunLoggerWeb.AccountController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Accounts
  alias MailgunLogger.Account

  def index(conn, _) do
    accounts = Accounts.list_accounts()
    render(conn, :index, accounts: accounts)
  end

  def new(conn, _) do
    changeset = Account.changeset(%Account{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"account" => params}) do
    case Accounts.create_account(params) do
      {:ok, _} -> redirect(conn, to: Routes.account_path(conn, :index))
      {:error, changeset} -> render(conn, :new, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    account = Accounts.get_account_by_id(id)
    changeset = Account.changeset(account)
    render(conn, :edit, changeset: changeset, account: account)
  end

  def update(conn, %{"id" => id, "account" => params}) do
    account = Accounts.get_account_by_id(id)

    case Accounts.update_account(account, params) do
      {:ok, _} -> redirect(conn, to: Routes.account_path(conn, :index))
      {:error, changeset} -> render(conn, :update, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    {:ok, _} =
      Accounts.get_account_by_id(id)
      |> Accounts.delete_account()

    conn
    |> put_flash(:info, "Account deleted successfully.")
    |> redirect(to: Routes.account_path(conn, :index))
  end
end
