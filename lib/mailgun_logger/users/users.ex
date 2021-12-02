defmodule MailgunLogger.Users do
  import Ecto.Query, warn: false

  alias MailgunLogger.Repo
  alias MailgunLogger.User
  alias MailgunLogger.Roles

  @spec assign_role(User.t(), String.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()} | nil
  def assign_role(user, role_name) do
    case Roles.get_role_by_name(role_name) do
      nil ->
        nil

      role ->
        user
        |> Repo.preload([:roles])
        |> User.changeset()
        |> Ecto.Changeset.put_assoc(:roles, [role])
        |> Repo.update()
    end
  end

  @spec get_user!(integer | String.t()) :: User.t() | no_return()
  def get_user!(id) do
    from(
      u in User,
      where: u.id == ^id,
      left_join: roles in assoc(u, :roles),
      preload: [roles: roles]
    )
    |> Repo.one!()
  end

  @spec get_user(integer | String.t()) :: User.t() | nil
  def get_user(id) do
    from(
      u in User,
      where: u.id == ^id,
      left_join: roles in assoc(u, :roles),
      preload: [roles: roles]
    )
    |> Repo.one()
  end

  @spec get_user_by_token!(String.t()) :: User.t() | no_return()
  def get_user_by_token!(token) do
    from(
      u in User,
      where: u.token == ^token,
      left_join: roles in assoc(u, :roles),
      preload: [roles: roles]
    )
    |> Repo.one!()
  end

  @spec get_user_by_token(String.t()) :: User.t() | nil
  def get_user_by_token(token) do
    from(
      u in User,
      where: u.token == ^token,
      left_join: roles in assoc(u, :roles),
      preload: [roles: roles]
    )
    |> Repo.one()
  end

  @spec authenticate(String.t(), String.t()) :: any
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
        # IO.puts("PRE ARGON")
        # IO.inspect(user)
        # IO.inspect(password)
        r = Argon2.check_pass(user, password)
        # IO.puts("POST ARGON")

        r
    end
  end

  @spec get_user_by_email(String.t()) :: User.t() | nil
  def get_user_by_email(email) do
    from(
      u in User,
      where: u.email == ^email
    )
    |> Repo.one()
  end

  @spec get_user_by_reset_token(String.t()) :: User.t() | nil
  def get_user_by_reset_token(reset_token) do
    from(
      u in User,
      where: u.reset_token == ^reset_token,
      left_join: roles in assoc(u, :roles),
      preload: [roles: roles]
    )
    |> Repo.one()
  end

  @spec gen_password_reset_token(String.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
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

  @spec reset_password(User.t(), map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def reset_password(%User{} = user, attrs \\ %{}) do
    user
    |> User.password_reset_changeset(attrs)
    |> Ecto.Changeset.change(reset_token: nil)
    |> Repo.update()
  end

  @spec update_user(User.t(), map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def update_user(user, params) do
    user
    |> User.update_changeset(params)
    |> Repo.update()
  end

  @spec any_users?() :: boolean
  def any_users?(), do: length(Repo.all(User)) > 0

  @spec create_admin(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_admin(attrs) do
    %User{}
    |> User.admin_changeset(attrs)
    |> Repo.insert()
  end
end
