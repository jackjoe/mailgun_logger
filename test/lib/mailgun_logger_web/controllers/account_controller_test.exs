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

  test "shows the new account form", %{conn: conn} do
    conn = get(conn, ~p"/accounts/new")
    assert headings(html_response(conn, 200)) == ["New account"]
  end

  test "creates an account", %{conn: conn} do
    conn =
      post(conn, ~p"/accounts", %{"account" => %{"domain" => "mg.example.com", "api_key" => "key"}})

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
  end
end
