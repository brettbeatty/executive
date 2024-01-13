defmodule Executive.Types.Float do
  @moduledoc """
  Floats are floating-point numbers.

  This type is aliased as `:float`.
  """
  @behaviour Executive.Type

  @impl Executive.Type
  def name(_params) do
    "float"
  end

  @impl Executive.Type
  def parse(_params, _flag, raw) when is_float(raw) do
    {:ok, raw}
  end

  @impl Executive.Type
  def raw_type(_params) do
    :float
  end

  @impl Executive.Type
  def spec(_params) do
    quote do
      float()
    end
  end
end
