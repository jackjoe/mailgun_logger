defmodule MailgunLogger.Authorization do

  alias __MODULE__

  defstruct role: nil, visit: %{}

  @spec can(String.t()) :: %Authorization{}
  def can(role) when is_binary(role) do
    grant(role)
    |> visit(:default_resource)
  end

  @spec grant(String.t()) :: %Authorization{}
  def grant(role) do
    %Authorization{role: role}
  end

  @spec visit(%Authorization{}, atom()) :: %Authorization{}
  def visit(%Authorization{visit: visit} = authorization, resource) do
    granted_visit =
      Map.put(visit, resource, true)

    %Authorization{authorization | visit: granted_visit}
  end

  @spec has_access?(%Authorization{}, atom()) :: boolean()
  def has_access?(%Authorization{visit: visit}, resource) do
    Map.get(visit, resource, false)
  end
end
