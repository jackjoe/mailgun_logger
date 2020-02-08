defmodule MailgunLogger.Role do
  use Ecto.Schema

  @moduledoc "Simple user role."

  import Ecto.Changeset

  alias MailgunLogger.Role
  alias MailgunLogger.User
  alias MailgunLogger.UserRole

  @type t() :: %__MODULE__{
          name: String.t(),
          users: Ecto.Association.NotLoaded.t() | [User.t()],
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "roles" do
    field(:name, :string)

    many_to_many(:users, User, join_through: UserRole)

    timestamps()
  end

  @spec changeset(Role.t()) :: Ecto.Changeset.t()
  def changeset(%Role{} = role, params \\ %{}) do
    role
    |> cast(params, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
