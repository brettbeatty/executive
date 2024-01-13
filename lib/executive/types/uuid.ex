defmodule Executive.Types.UUID do
  @moduledoc """
  UUIDs are a popular argument in data management mix tasks.

  This type just checks for the common format. If a value is in the 8-4-4-4-12
  format, this type will accept it.

      iex> alias Executive.Schema
      iex> Schema.new()
      ...> |> Schema.put_option(:my_option, :uuid)
      ...> |> Schema.parse(["--my-option", "00000000-0000-0000-0000-000000000000"])
      {:ok, [], [my_option: "00000000-0000-0000-0000-000000000000"]}

  Values in any other format will not be accepted.

      iex> alias Executive.Schema
      iex> Schema.new()
      ...> |> Schema.put_option(:my_option, :uuid)
      ...> |> Schema.parse(["--my-option", "00000000000000000000000000000000"])

  This type is aliased as `:uuid`.
  """
  @behaviour Executive.Type

  @impl Executive.Type
  def name(_params) do
    "UUID"
  end

  @impl Executive.Type
  def parse(_params, _flag, raw) do
    uppercase = String.upcase(raw)

    with <<a::8-bytes, ?-, b::4-bytes, ?-, c::4-bytes, ?-, d::4-bytes, ?-, e::12-bytes>> <-
           uppercase,
         {:ok, _} <- Base.decode16(a),
         {:ok, _} <- Base.decode16(b),
         {:ok, _} <- Base.decode16(c),
         {:ok, _} <- Base.decode16(d),
         {:ok, _} <- Base.decode16(e) do
      {:ok, raw}
    else
      _not_uuid ->
        {:error, ["Expected type UUID, got ", inspect(raw)]}
    end
  end

  @impl Executive.Type
  def raw_type(_params) do
    :string
  end

  @impl Executive.Type
  def spec(_params) do
    quote do
      <<_::288>>
    end
  end
end
