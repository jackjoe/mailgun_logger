defmodule MailgunLoggerTest do
  use MailgunLogger.DataCase

  test "process_account returns the error of a 400 response" do
    account = insert(:account)

    Req.Test.stub(
      Mailgun.Client,
      &Req.Test.json(Plug.Conn.put_status(&1, 400), %{"error" => %{"message" => "bad"}})
    )

    assert MailgunLogger.process_account(account) == {:error, "bad"}
  end

  test "process_account returns a network error" do
    account = insert(:account)
    Req.Test.stub(Mailgun.Client, &Req.Test.transport_error(&1, :timeout))

    assert {:error, %Req.TransportError{reason: :timeout}} =
             MailgunLogger.process_account(account)
  end
end
