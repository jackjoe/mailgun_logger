defmodule MailgunLogger.User do
  @moduledoc "User"

  use Ecto.Schema
  import Ecto.Changeset

  alias MailgunLogger.User
  alias MailgunLogger.Role
  alias MailgunLogger.Roles
  alias MailgunLogger.UserRole

  @email_format ~r/^[A-Za-z0-9._%+-]+[A-Za-z0-9]@[A-Za-z0-9.-]+\.[A-Za-z]{2,63}$/

  @type t() :: %__MODULE__{
          id: integer(),
          email: String.t(),
          firstname: String.t(),
          lastname: String.t(),
          token: String.t(),
          encrypted_password: String.t(),
          reset_token: String.t(),
          is_test: boolean(),
          password: String.t(),
          password_confirmation: String.t(),
          roles: Ecto.Association.NotLoaded.t() | [Role.t()],
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "users" do
    field(:email, :string)
    field(:firstname, :string)
    field(:lastname, :string)
    field(:token, :string)
    field(:encrypted_password, :string)
    field(:reset_token, :string, default: nil)
    field(:is_test, :boolean, default: false)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)

    many_to_many(:roles, Role, join_through: UserRole, on_replace: :delete)

    timestamps()
  end

  @doc false
  @spec changeset(User.t(), map()) :: Ecto.Changeset.t()
  def changeset(%User{} = user, attrs \\ %{}) do
    user
    |> cast(attrs, [:email, :password, :password_confirmation])
    |> validate_required([:email, :password, :password_confirmation])
    |> validate_confirmation(:password)
    |> update_change(:email, &String.downcase/1)
    |> validate_format(:email, @email_format)
    |> validate_length(:password, min: 6)
    |> unique_constraint(:email)
    |> hash_password()
    |> generate_token()
    |> is_test()
  end

  @doc false
  @spec update_changeset(User.t(), map()) :: Ecto.Changeset.t()
  def update_changeset(%User{} = user, attrs \\ %{}) do
    user
    |> cast(attrs, [:email])
    |> update_change(:email, &String.downcase/1)
    |> validate_format(:email, @email_format)
    |> unique_constraint(:email)
    |> is_test()
  end

  @doc "Used when creating an admin, e.g. from the setup flow"
  @spec admin_changeset(User.t(), map()) :: Ecto.Changeset.t()
  def admin_changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:email, :password, :password_confirmation])
    |> validate_required([:email, :password, :password_confirmation])
    |> validate_confirmation(:password)
    |> update_change(:email, &String.downcase/1)
    |> validate_format(:email, @email_format)
    |> validate_length(:password, min: 6)
    |> unique_constraint(:email)
    |> hash_password()
    |> generate_token()
    |> put_assoc(:roles, [Roles.get_role_by_name("admin")])
    |> is_test()
  end

  @doc false
  @spec password_forgot_changeset(User.t(), map()) :: Ecto.Changeset.t()
  def password_forgot_changeset(%User{} = user, params \\ %{}) do
    user
    |> cast(params, [:reset_token])
  end

  @doc false
  @spec password_reset_changeset(User.t(), map()) :: Ecto.Changeset.t()
  def password_reset_changeset(%User{} = user, params) do
    user
    |> cast(params, [:reset_token, :password, :password_confirmation])
    |> validate_required([:password, :password_confirmation])
    |> validate_confirmation(:password)
    |> hash_password()
  end

  @spec hash_password(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp hash_password(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, encrypted_password: Argon2.hash_pwd_salt(password))
  end

  defp hash_password(changeset), do: changeset

  defp generate_token(%Ecto.Changeset{} = changeset) do
    length = 75
    token = :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
    put_change(changeset, :token, token)
  end

  defp is_test(%Ecto.Changeset{valid?: true, changes: %{email: email}} = changeset) do
    put_change(
      changeset,
      :is_test,
      Regex.match?(~r/@(noort|jackjoe|daele)\./, email)
    )
  end

  defp is_test(changeset), do: changeset

  @doc false
  def full_name(nil), do: ""
  def full_name(%User{lastname: nil, firstname: nil, email: nil}), do: ""
  def full_name(%User{lastname: nil, firstname: nil} = user), do: user.email
  def full_name(%User{lastname: nil} = user), do: user.firstname
  def full_name(%User{firstname: nil} = user), do: user.lastname
  def full_name(%User{} = user), do: user.firstname <> " " <> user.lastname
end
