defmodule MailgunLoggerWeb.PageHTML do
  @moduledoc false
  use MailgunLoggerWeb, :html

  embed_templates("page_html/*")

  def print_date_labels(days) do
    days
    |> Enum.map(&Calendar.strftime(&1, "%Y-%m-%d %H:%M"))
    |> Jason.encode!()
  end
end
