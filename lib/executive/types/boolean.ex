defmodule Executive.Types.Boolean do
  @moduledoc """
  Boolean options refine as `true` or `false` depending on switch presence.

  Option is true when switch is provided or false when its
  [negation switch](https://hexdocs.pm/elixir/OptionParser.html#parse/2-negation-switches)
  is used.

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
  def raw_type(_params) do
    :boolean
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
