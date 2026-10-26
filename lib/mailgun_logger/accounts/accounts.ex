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

  @doc """
  Saves the result of a run for the account: `{:ok, event_count}` or
  `{:error, message}`.
  """
  @spec record_run(Account.t(), {:ok, non_neg_integer()} | {:error, String.t()}) ::
          {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def record_run(%Account{} = account, result) do
    attrs =
      case result do
        {:ok, count} ->
          %{last_run_status: "ok", last_run_error: nil, last_run_event_count: count}

        {:error, message} ->
          %{last_run_status: "error", last_run_error: message, last_run_event_count: nil}
      end

    account
    |> Account.run_changeset(Map.put(attrs, :last_run_at, DateTime.utc_now()))
    |> Repo.update()
  end

  @doc """
  Summarizes the last run over all accounts: the time of the most recent run
  and the number of accounts per result. Returns nil before the first run.
  """
  @spec last_run_summary() ::
          %{at: DateTime.t(), ok: non_neg_integer(), error: non_neg_integer()} | nil
  def last_run_summary() do
    from(a in Account,
      where: not is_nil(a.last_run_at),
      select: %{
        at: max(a.last_run_at),
        ok: filter(count(a.id), a.last_run_status == "ok"),
        error: filter(count(a.id), a.last_run_status == "error")
      }
    )
    |> Repo.one()
    |> case do
      %{at: nil} -> nil
      summary -> summary
    end
  end

  @spec count_accounts() :: non_neg_integer()
  def count_accounts do
    Repo.aggregate(Account, :count)
  end
end
