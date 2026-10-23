defmodule MailgunLogger.MailerTest do
  use ExUnit.Case, async: true

  import Swoosh.Email

  test "the Mailgun adapter posts to the configured EU endpoint with basic auth" do
    test_pid = self()

    Req.Test.stub(__MODULE__, fn conn ->
      send(test_pid, {:request, conn.method, conn.host, conn.request_path, conn.req_headers})
      Req.Test.json(conn, %{"id" => "<id@mg.example.com>", "message" => "Queued. Thank you."})
    end)

    config =
      :mailgun_logger
      |> Application.get_env(MailgunLogger.Mailer)
      |> Keyword.merge(api_key: "key-test", domain: "mg.example.com")

    email =
      new()
      |> from("from@example.com")
      |> to("to@example.com")
      |> subject("Subject")
      |> text_body("Body")
      |> put_private(:client_options, plug: {Req.Test, __MODULE__})

    assert {:ok, %{id: "<id@mg.example.com>"}} = Swoosh.Adapters.Mailgun.deliver(email, config)

    assert_received {:request, "POST", "api.eu.mailgun.net", "/v3/mg.example.com/messages",
                     headers}

    assert {"authorization", "Basic " <> Base.encode64("api:key-test")} in headers
  end
end
