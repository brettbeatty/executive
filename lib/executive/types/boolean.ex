defmodule Executive.Types.Boolean do
  @moduledoc """
  Boolean options refine as `true` or `false` depending on switch presence.

  Option is true when switch is provided or false when its
  [negation switch](https://hexdocs.pm/elixir/OptionParser.html#parse/2-negation-switches)
  is used.

  This type is aliased as `:boolean`.
  """
  @behaviour Executive.Type

  @impl Executive.Type
  def name(_params) do
    "boolean"
  end

  @impl Executive.Type
  def parse(_params, _flag, raw) when is_boolean(raw) do
    {:ok, raw}
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
end
