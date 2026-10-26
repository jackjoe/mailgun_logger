defmodule MailgunLoggerWeb.AccountControllerTest do
  use MailgunLoggerWeb.ConnCase

  alias MailgunLogger.Accounts

  setup :log_in_user

  test "lists the accounts", %{conn: conn} do
    account = insert(:account)
    conn = get(conn, ~p"/accounts")
    html = html_response(conn, 200)
    assert headings(html) == ["Accounts"]
    assert html =~ account.domain
    assert html =~ ~s(href="/accounts/#{account.id}/edit")
  end

  test "shows only the end of the API key", %{conn: conn} do
    insert(:account, api_key: "key-0123456789abcd")
    html = conn |> get(~p"/accounts") |> html_response(200)
    assert html =~ "••••abcd"
    refute html =~ "key-0123456789abcd"
  end

  test "shows the result of the last run", %{conn: conn} do
    insert(:account,
      domain: "ok.example.com",
      last_run_at: DateTime.add(DateTime.utc_now(), -180, :second),
      last_run_status: "ok",
      last_run_event_count: 12
    )

    insert(:account,
      domain: "error.example.com",
      last_run_at: DateTime.add(DateTime.utc_now(), -7200, :second),
      last_run_status: "error",
      last_run_error: "401: unauthorized"
    )

    insert(:account, domain: "never.example.com")

    rows =
      conn
      |> get(~p"/accounts")
      |> html_response(200)
      |> LazyHTML.from_document()
      |> LazyHTML.query("tbody tr")
      |> Enum.map(&(&1 |> LazyHTML.text() |> String.split() |> Enum.join(" ")))

    assert Enum.find(rows, &(&1 =~ "ok.example.com")) =~ "3 min ago ok, 12 events"
    assert Enum.find(rows, &(&1 =~ "error.example.com")) =~ "2 hours ago 401: unauthorized"
    assert Enum.find(rows, &(&1 =~ "never.example.com")) =~ "never"
  end

  test "shows the new account form", %{conn: conn} do
    conn = get(conn, ~p"/accounts/new")
    assert headings(html_response(conn, 200)) == ["New account"]
  end

  test "creates an account", %{conn: conn} do
    conn =
      post(conn, ~p"/accounts", %{
        "account" => %{"domain" => "mg.example.com", "api_key" => "key"}
      })

    assert redirected_to(conn) == ~p"/accounts"
    assert [%{domain: "mg.example.com"}] = Accounts.list_accounts()
  end

  test "shows errors for an invalid account", %{conn: conn} do
    conn = post(conn, ~p"/accounts", %{"account" => %{"domain" => ""}})
    assert html_response(conn, 200) =~ "can&#39;t be blank"
  end

  test "shows the edit account form", %{conn: conn} do
    account = insert(:account)
    conn = get(conn, ~p"/accounts/#{account}/edit")
    html = html_response(conn, 200)
    assert headings(html) == ["Edit account"]
    assert html =~ ~s(value="#{account.domain}")
  end

  test "updates an account", %{conn: conn} do
    account = insert(:account)
    conn = put(conn, ~p"/accounts/#{account}", %{"account" => %{"domain" => "new.example.com"}})
    assert redirected_to(conn) == ~p"/accounts"
    assert Accounts.get_account_by_id(account.id).domain == "new.example.com"
  end

  test "deletes an account", %{conn: conn} do
    account = insert(:account)
    conn = delete(conn, ~p"/accounts/#{account}")
    assert redirected_to(conn) == ~p"/accounts"
    assert Accounts.list_accounts() == []

    conn = conn |> recycle() |> get(~p"/accounts")
    assert html_response(conn, 200) =~ "Account deleted successfully."
  end
end
