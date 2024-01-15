defmodule Executive.Types.Boolean do
  @moduledoc """
  Boolean options refine as `true` or `false` depending on switch presence.

  Options parse as true when the primary switch is used.

      iex> Schema.new()
      ...> |> Schema.put_option(:my_option, :boolean)
      ...> |> Schema.parse(["--my-option"])
      {:ok, [], [my_option: true]}

  Options parse as false when the negation switch is used.

      iex> Schema.new()
      ...> |> Schema.put_option(:my_option, :boolean)
      ...> |> Schema.parse(["--no-my-option"])
      {:ok, [], [my_option: false]}

  Any aliases for the option are seen as truthy.

      iex> Schema.new()
      ...> |> Schema.put_option(:my_option, :boolean, alias: :o)
      ...> |> Schema.parse(["-o"])
      {:ok, [], [my_option: true]}

  This type is aliased as `:boolean`.
  """
  @behaviour Executive.Type
  alias Executive.Schema.Option

  @impl Executive.Type
  def capture?(_params, _flag) do
    false
  end

  @impl Executive.Type
  def name(_params) do
    "boolean"
  end

  @impl Executive.Type
  def parse(_params, flag, _raw) when is_boolean(flag) do
    {:ok, flag}
  end

  @impl Executive.Type
  def spec(_params) do
    quote do
      boolean()
    end
  end

  @impl Executive.Type
  def switches(_params, name, aliases) do
    [
      {Option.switch_name(name), true},
      {Option.switch_name("no_#{name}"), false}
      | Enum.map(aliases, &{Option.switch_alias(&1), true})
    ]
  end
end
