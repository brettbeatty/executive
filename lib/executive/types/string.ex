defmodule Executive.Types.String do
  @moduledoc """
  Strings are sequences of characters.

  This type is aliased as `:string`.
  """
  @behaviour Executive.Type

  @impl Executive.Type
  def name(_params) do
    "string"
  end

  @impl Executive.Type
  def parse(_params, raw) when is_binary(raw) do
    {:ok, raw}
  end

  @impl Executive.Type
  def raw_type(_params) do
    :string
  end

  @impl Executive.Type
  def spec(_params) do
    quote do
      String.t()
    end
  end
end
