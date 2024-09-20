defmodule MailgunLogger.UserRole do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias MailgunLogger.Role
  alias MailgunLogger.User
  alias MailgunLogger.UserRole

  @type t() :: %__MODULE__{
          id: integer(),
          role: Role.t(),
          role_id: integer(),
          user: User.t(),
          user_id: integer(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "roles_users" do
    belongs_to(:user, User)
    belongs_to(:role, Role)

    timestamps()
  end

  @doc false
  @spec changeset(UserRole.t(), map()) :: Ecto.Changeset.t()
  def changeset(%UserRole{} = user_role, attrs \\ %{}) do
    user_role
    |> cast(attrs, [:user_id, :role_id])
    |> validate_required([:user_id, :role_id])
  end

  # Haalt de huidige rol op die een ingelogde user heeft
  @spec get_current_user_role(map()) :: String.t()
  def get_current_user_role(user) do
    case user.roles do
      # We nemen de waarde van role uit de lijst en gooien de rest weg.
      # Vervolgens extraheren we er de naam uit
      [role | _] -> role.name
      [] -> "No role"
    end
  end

end
