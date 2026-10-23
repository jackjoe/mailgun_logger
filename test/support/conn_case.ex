defmodule MailgunLoggerWeb.ConnCase do
  @moduledoc """
  This module defines the setup for tests requiring
  a connection to the endpoint.

  Every test runs inside a transaction which is reset
  at the beginning of the test unless the test case is
  marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint MailgunLoggerWeb.Endpoint

      use MailgunLoggerWeb, :verified_routes

      import Plug.Conn
      import Phoenix.ConnTest
      import MailgunLogger.Factory
      import MailgunLoggerWeb.ConnCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(MailgunLogger.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(MailgunLogger.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that inserts a user and signs the user in.
  """
  def log_in_user(%{conn: conn}) do
    user = MailgunLogger.Factory.insert(:user)
    %{conn: Phoenix.ConnTest.init_test_session(conn, current_user_id: user.id), user: user}
  end

  @doc """
  Returns the text of the `h1` and `h2` headings in the given HTML.
  """
  def headings(html) do
    html
    |> LazyHTML.from_document()
    |> LazyHTML.query("h1, h2")
    |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))
  end
end
