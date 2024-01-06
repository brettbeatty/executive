defmodule Executive.Types.Count do
  @moduledoc """
  Count options count uses of the corresponding switch.

  These options, when present, will be positive integers.

  This type is aliased as `:count`.
  """
  @behaviour Executive.Type

  @impl Executive.Type
  def name(_params) do
    "count"
  end

  @impl Executive.Type
  def parse(raw, _params) when is_integer(raw) and raw > 0 do
    {:ok, raw}
  end

  @impl Executive.Type
  def raw_type(_params) do
    :count
  end

  @impl Executive.Type
  def spec(_params) do
    quote do
      pos_integer()
    end
  end
end
