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
          password: String.t(),
          roles: Ecto.Association.NotLoaded.t() | [Role.t()],
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "users" do
    field(:email, :string)
    field(:firstname, :string, default: "")
    field(:lastname, :string, default: "")
    field(:token, :string)
    field(:encrypted_password, :string)
    field(:reset_token, :string, default: nil)
    field(:password, :string, virtual: true)

    many_to_many(:roles, Role, join_through: UserRole, on_replace: :delete)

    timestamps()
  end

  @doc false
  @spec changeset(User.t(), map()) :: Ecto.Changeset.t()
  def changeset(%User{} = user, attrs \\ %{}) do
    user
    |> cast(attrs, [:firstname, :lastname, :email, :password])
    |> validate_required([:email, :password])
    |> update_change(:email, &String.downcase/1)
    |> validate_format(:email, @email_format)
    |> validate_length(:password, min: 8)
    |> unique_constraint(:email)
    |> hash_password()
    |> generate_token()
  end

  @doc false
  @spec create_changeset(User.t(), map()) :: Ecto.Changeset.t()
  def create_changeset(%User{} = user, attrs \\ %{}) do
    user
    |> cast(attrs, [:firstname, :lastname, :email, :password])
    |> validate_required([:email, :password])
    |> update_change(:email, &String.downcase/1)
    |> validate_format(:email, @email_format)
    |> validate_length(:password, min: 8)
    |> unique_constraint(:email)
    |> hash_password()
    |> generate_token()
    # put_assoc/3 always replaces all associations (no inserts)
    # Using put_assoc/2 because we already have the %Role{} struct from the database.
    # cast_assoc/2 would be used when whe have a :map with form data.
    |> put_assoc(:roles, attrs["roles"] || [])
  end

  @doc false
  @spec update_changeset(User.t(), map()) :: Ecto.Changeset.t()
  def update_changeset(%User{} = user, attrs \\ %{}) do
    user
    |> cast(attrs, [:firstname, :lastname, :email])
    |> update_change(:email, &String.downcase/1)
    |> validate_format(:email, @email_format)
    |> unique_constraint(:email)
    # put_assoc/3 always replaces all associations (no inserts)
    # Using put_assoc/2 because we already have the %Role{} struct from the database.
    # cast_assoc/2 would be used when whe have a :map with form data.
    |> put_assoc(:roles, attrs["roles"] || [])
  end

  @doc "Used when creating an admin, e.g. from the setup flow"
  @spec admin_changeset(User.t(), map()) :: Ecto.Changeset.t()
  def admin_changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> update_change(:email, &String.downcase/1)
    |> validate_format(:email, @email_format)
    |> validate_length(:password, min: 8)
    |> unique_constraint(:email)
    |> hash_password()
    |> generate_token()
    |> put_assoc(:roles, [Roles.get_role_by_name("admin")])
  end

  @doc false
  @spec password_forgot_changeset(User.t(), map()) :: Ecto.Changeset.t()
  def password_forgot_changeset(%User{} = user, params \\ %{}) do
    cast(user, params, [:reset_token])
  end

  @doc false
  @spec password_reset_changeset(User.t(), map()) :: Ecto.Changeset.t()
  def password_reset_changeset(%User{} = user, params) do
    user
    |> cast(params, [:reset_token, :password])
    |> validate_required([:password])
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

  @doc false
  def full_name(nil), do: ""
  def full_name(%User{lastname: nil, firstname: nil, email: nil}), do: ""
  def full_name(%User{lastname: nil, firstname: nil} = user), do: user.email
  def full_name(%User{lastname: nil} = user), do: user.firstname
  def full_name(%User{firstname: nil} = user), do: user.lastname
  def full_name(%User{} = user), do: user.firstname <> " " <> user.lastname
end
