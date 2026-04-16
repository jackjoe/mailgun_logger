defmodule MailgunLogger.Users do
  import Ecto.Query, warn: false

  alias MailgunLogger.Repo
  alias MailgunLogger.User
  alias MailgunLogger.Roles # nodig voor rollen ophalen bij create/update user with roles


  @type ecto_user() :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  @type maybe_user() :: User.t() | nil

  @spec list_users() :: [User.t()]
  def list_users() do
    Repo.all(User) |> Repo.preload(:roles)
  end

  @spec get_user!(integer | String.t()) :: User.t()
  def get_user!(id) do
    from(
      u in User,
      where: u.id == ^id,
      left_join: roles in assoc(u, :roles),
      preload: [roles: roles]
    )
    |> Repo.one!()
  end

  @spec get_user(integer | String.t()) :: maybe_user()
  def get_user(id) do
    from(
      u in User,
      where: u.id == ^id,
      left_join: roles in assoc(u, :roles),
      preload: [roles: roles]
    )
    |> Repo.one()
  end

  @spec get_user_by_token!(String.t()) :: User.t()
  def get_user_by_token!(token) do
    from(
      u in User,
      where: u.token == ^token,
      left_join: roles in assoc(u, :roles),
      preload: [roles: roles]
    )
    |> Repo.one!()
  end

  @spec get_user_by_token(String.t()) :: maybe_user()
  def get_user_by_token(token) do
    from(
      u in User,
      where: u.token == ^token,
      left_join: roles in assoc(u, :roles),
      preload: [roles: roles]
    )
    |> Repo.one()
  end

  @spec authenticate(String.t(), String.t()) ::
          {:error, :unknown_user} | {:error, any()} | {:ok, User.t()}
  def authenticate(email, password) do
    from(
      u in User,
      where: u.email == ^email,
      left_join: roles in assoc(u, :roles),
      preload: [roles: roles]
    )
    |> Repo.one()
    |> case do
      nil ->
        {:error, :unknown_user}

      user ->
        case Argon2.verify_pass(password, user.encrypted_password) do
          true -> {:ok, user}
          false -> {:error, "invalid password"}
        end
    end
  end

  @spec get_user_by_email(String.t()) :: maybe_user()
  def get_user_by_email(email) do
    from(
      u in User,
      where: u.email == ^email
    )
    |> Repo.one()
  end

  @spec get_user_by_reset_token(String.t()) :: maybe_user()
  def get_user_by_reset_token(reset_token) do
    from(
      u in User,
      where: u.reset_token == ^reset_token,
      left_join: roles in assoc(u, :roles),
      preload: [roles: roles]
    )
    |> Repo.one()
  end

  @spec gen_password_reset_token(String.t()) :: ecto_user()
  def gen_password_reset_token(email) do
    from(
      u in User,
      where: u.email == ^email
    )
    |> Repo.one()
    |> case do
      nil ->
        {:error, :unknown_user}

      user ->
        token = gen_token(46)

        user
        |> User.password_forgot_changeset(%{reset_token: token})
        |> Repo.update()
    end
  end

  defp gen_token(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, length)
  end

  @spec reset_password(User.t(), map()) :: ecto_user()
  def reset_password(%User{} = user, attrs \\ %{}) do
    user
    |> User.password_reset_changeset(attrs)
    |> Ecto.Changeset.change(reset_token: nil)
    |> Repo.update()
  end

  @spec any_users?() :: boolean()
  def any_users?(), do: Repo.exists?(from(u in User, select: u.id))

  @spec create_admin(map()) :: ecto_user()
  def create_admin(attrs) do
    %User{}
    |> User.admin_changeset(attrs)
    |> Repo.insert()
  end

  @spec create_user(map) :: ecto_user()
  def create_user(params) do
    %User{}
    |> User.changeset(params)
    |> Repo.insert()
  end

  @spec update_user(User.t(), map) :: ecto_user()
  def update_user(user, params) do
    user
    |> User.update_changeset(params)
    |> Repo.update()
  end

  # maak nieuwe User aan met gegeven rollen
  @spec create_user_with_roles(map(), [integer()]) :: ecto_user()
  def create_user_with_roles(params, role_ids) do
    roles = Roles.get_roles_by_id(role_ids)

    %User{}
    |> User.changeset(params)
    |> User.with_roles(roles)
    |> Repo.insert()
  end

  # update user en overschrijft rollen
  @spec update_user_with_roles(User.t(), map(), [integer()]) :: ecto_user()
  def update_user_with_roles(user, params, role_ids) do
    roles = Roles.get_roles_by_id(role_ids)

    user
    |> User.update_changeset(params)
    |> User.with_roles(roles)
    |> Repo.update()
  end

  @spec delete_user(User.t()) :: ecto_user()
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end
end
