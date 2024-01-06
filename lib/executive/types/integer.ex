defmodule Executive.Types.Integer do
  @moduledoc """
  Integers are whole numbers.

  This type is aliased as `:integer`.
  """
  @behaviour Executive.Type

  @impl Executive.Type
  def name(_params) do
    "integer"
  end

  @impl Executive.Type
  def parse(raw, _params) when is_integer(raw) do
    {:ok, raw}
  end

  @impl Executive.Type
  def raw_type(_params) do
    :integer
  end

  @impl Executive.Type
  def spec(_params) do
    quote do
      integer()
    end
  end
end
