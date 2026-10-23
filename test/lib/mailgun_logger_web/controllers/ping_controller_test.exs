defmodule MailgunLoggerWeb.PingControllerTest do
  use MailgunLoggerWeb.ConnCase

  test "answers on /ping and /health", %{conn: conn} do
    assert conn |> get(~p"/ping") |> text_response(200) == "pong"
    assert conn |> get(~p"/health") |> text_response(200) == "pong"
  end
end
