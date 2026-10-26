defmodule MailgunLoggerTest do
  use MailgunLogger.DataCase

  # The error paths log on purpose; keep that out of the test output.
  @moduletag :capture_log

  alias MailgunLogger.Account

  defp raw_event(id) do
    %{
      "id" => id,
      "event" => "delivered",
      "timestamp" => 1_792_760_000.0,
      "recipient" => "to@example.com",
      "message" => %{"headers" => %{"from" => "from@example.com", "subject" => "Hi"}}
    }
  end

  defp reload(account), do: Repo.get!(Account, account.id)

  test "process_account saves a successful run" do
    account = insert(:account)

    Req.Test.stub(
      Mailgun.Client,
      &Req.Test.json(&1, %{"items" => [raw_event("e1"), raw_event("e2")]})
    )

    MailgunLogger.process_account(account)

    account = reload(account)
    assert account.last_run_status == "ok"
    assert account.last_run_event_count == 2
    assert account.last_run_error == nil
    assert DateTime.diff(DateTime.utc_now(), account.last_run_at) < 5
  end

  test "process_account saves the error of a 401 response" do
    account = insert(:account)

    Req.Test.stub(
      Mailgun.Client,
      &Req.Test.text(Plug.Conn.put_status(&1, 401), ~s({"Error":"unauthorized"}))
    )

    assert {:error, 401, _body} = MailgunLogger.process_account(account)

    account = reload(account)
    assert account.last_run_status == "error"
    assert account.last_run_error == "401: unauthorized"
    assert account.last_run_event_count == nil
    assert account.last_run_at
  end

  test "process_account returns and saves the error of a 400 response" do
    account = insert(:account)

    Req.Test.stub(
      Mailgun.Client,
      &Req.Test.json(Plug.Conn.put_status(&1, 400), %{"error" => %{"message" => "bad"}})
    )

    assert MailgunLogger.process_account(account) == {:error, "bad"}
    assert %{last_run_status: "error", last_run_error: "bad"} = reload(account)
  end

  test "process_account returns and saves a network error" do
    account = insert(:account)
    Req.Test.stub(Mailgun.Client, &Req.Test.transport_error(&1, :timeout))

    assert {:error, %Req.TransportError{reason: :timeout}} =
             MailgunLogger.process_account(account)

    assert %{last_run_status: "error", last_run_error: "timeout"} = reload(account)
  end

  test "a successful run clears the previous error" do
    account = insert(:account, last_run_status: "error", last_run_error: "401: unauthorized")
    Req.Test.stub(Mailgun.Client, &Req.Test.json(&1, %{"items" => []}))

    MailgunLogger.process_account(account)

    assert %{last_run_status: "ok", last_run_error: nil, last_run_event_count: 0} =
             reload(account)
  end
end
