defmodule MailgunLogger.UserFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MailgunLogger.Users` context.
  """

  @doc """
  Generate a user with role 'admin'
  """
  def admin_user_fixture(attrs \\ %{}) do
    {:ok, admin} =
      attrs
      |> Enum.into(%{
        "email" => "admin@example.com",
        "password" => "admin_password"
      })
      |> MailgunLogger.Users.create_admin()

    admin
  end

  @doc """
  Generate a user with role 'member'
  """
  def member_user_fixture(attrs \\ %{}) do
    {:ok, member} =
      attrs
      |> Enum.into(%{
        "email" => "member@example.com",
        "password" => "member_password",
        "firstname" => "First name",
        "lastname" => "Last name"
      })
      |> MailgunLogger.Users.create_user!()
      |> MailgunLogger.Users.assign_role("member")

    member
  end
end
