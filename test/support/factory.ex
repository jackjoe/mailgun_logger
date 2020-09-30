defmodule MailgunLogger.Factory do
  use ExMachina.Ecto, repo: MailgunLogger.Repo

  alias MailgunLogger.Account
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
