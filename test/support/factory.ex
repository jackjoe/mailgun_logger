defmodule MailgunLogger.Factory do
  use ExMachina.Ecto, repo: MailgunLogger.Repo

  alias MailgunLogger.Account
  alias MailgunLogger.Event
  alias MailgunLogger.User
  alias MailgunLogger.Role
  alias MailgunLogger.UserRole

  @password "password"
  @encrypted_password Argon2.hash_pwd_salt("password")

  def account_factory() do
    %Account{
      api_key: sequence(:api_key, &"api_key_#{&1}"),
      domain: sequence(:domain, &"#{&1}.com")
    }
  end

  def event_factory() do
    %Event{
      api_id: sequence(:api_id, &"api_id_#{&1}"),
      event: "delivered",
      log_level: "info",
      method: "http",
      recipient: sequence(:recipient, &"to_#{&1}@example.com"),
      message_from: "from@example.com",
      message_subject: sequence(:subject, &"subject #{&1}"),
      message_id: sequence(:message_id, &"mid_#{&1}"),
      timestamp: ~N[2026-01-01 00:00:00],
      account: build(:account)
    }
  end

  def user_factory() do
    %User{
      email: sequence(:email, &"joe-#{&1}@email.com"),
      password: @password,
      encrypted_password: @encrypted_password,
      roles: [build(:role)]
    }
  end

  def role_factory() do
    %Role{
      name: sequence(:role, &"Role_#{&1}")
    }
  end

  def user_role_factory() do
    %UserRole{}
  end
end
