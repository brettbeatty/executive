defmodule Executive.Types.Date do
  @moduledoc """
  DateTime parses from an ISO 8601 date.

      iex> Schema.new()
      ...> |> Schema.put_option(:my_option, :date)
      ...> |> Schema.parse(["--my-option", "2024-01-01"])
      {:ok, [], [my_option: ~D[2024-01-01]]}

  This type is aliased as `:date`.
  """
  @behaviour Executive.Type

  @impl Executive.Type
  def name(_params) do
    "date"
  end

  @impl Executive.Type
  def parse(_params, _flag, raw) do
    case Date.from_iso8601(raw) do
      {:ok, datetime} ->
        {:ok, datetime}

      {:error, :invalid_format} ->
        :error

      {:error, :invalid_date} ->
        {:error, "invalid date"}

      {:error, error} when is_atom(error) ->
        :error
    end
  end

  @impl Executive.Type
  def spec(_params) do
    quote do
      Date.t()
    end
  end
end
