defmodule MailgunLoggerWeb.AccountController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Roles
  alias MailgunLogger.Accounts
  alias MailgunLogger.Account

  defp authorize!(conn, action) do
  user = conn.assigns.current_user

  if Roles.can?(user, action) do
    conn
  else
    conn
    |> put_flash(:error, "Not authorized")
    |> redirect(to: Routes.event_path(conn, :index))
    |> halt()
  end
end

  def index(conn, _) do
    conn = authorize!(conn, :manage_accounts)

    if conn.halted do
      conn
    else
      accounts = Accounts.list_accounts()
      render(conn, :index, accounts: accounts)
    end
  end

  def new(conn, _) do
    conn = authorize!(conn, :manage_accounts)

    if conn.halted do
      conn
    else
      changeset = Account.changeset(%Account{})
      render(conn, :new, changeset: changeset)
    end
  end

  def create(conn, %{"account" => params}) do
    conn = authorize!(conn, :manage_accounts)

    if conn.halted do
      conn
    else
      case Accounts.create_account(params) do
        {:ok, _} -> redirect(conn, to: Routes.account_path(conn, :index))
        {:error, changeset} -> render(conn, :new, changeset: changeset)
      end
    end
  end

  def edit(conn, %{"id" => id}) do
    conn = authorize!(conn, :manage_accounts)

    if conn.halted do
      conn
    else
      account = Accounts.get_account_by_id(id)
      changeset = Account.changeset(account)
      render(conn, :edit, changeset: changeset, account: account)
    end
  end

  def update(conn, %{"id" => id, "account" => params}) do
    conn = authorize!(conn, :manage_accounts)

    if conn.halted do
      conn
    else
      account = Accounts.get_account_by_id(id)

      case Accounts.update_account(account, params) do
        {:ok, _} -> redirect(conn, to: Routes.account_path(conn, :index))
        {:error, changeset} -> render(conn, :edit, changeset: changeset)
      end
    end
  end

  def delete(conn, %{"id" => id}) do
    conn = authorize!(conn, :manage_accounts)

    if conn.halted do
      conn
    else
      {:ok, _} =
        Accounts.get_account_by_id(id)
        |> Accounts.delete_account()

      conn
      |> put_flash(:info, "Account deleted successfully.")
      |> redirect(to: Routes.account_path(conn, :index))
    end
  end
end
