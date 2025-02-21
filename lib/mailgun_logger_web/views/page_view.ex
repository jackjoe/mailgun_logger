defmodule MailgunLoggerWeb.PageView do
  use MailgunLoggerWeb, :view
  @moduledoc false

  def print_date_labels(days) do
    days
    |> Enum.map(&Calendar.strftime(&1, "%Y-%m-%d %H:%M"))
    |> Jason.encode!()
  end
end
