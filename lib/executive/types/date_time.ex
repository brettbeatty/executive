defmodule Executive.Types.DateTime do
  @moduledoc """
  DateTime parses from an ISO 8601 datetime.

      iex> Schema.new()
      ...> |> Schema.put_option(:my_option, :datetime)
      ...> |> Schema.parse(["--my-option", "2024-01-01T00:00:00Z"])
      {:ok, [], [my_option: ~U[2024-01-01 00:00:00Z]]}

  This type is aliased as `:datetime`.
  """
  @behaviour Executive.Type

  @impl Executive.Type
  def name(_params) do
    "datetime"
  end

  @impl Executive.Type
  def parse(_params, raw) do
    case DateTime.from_iso8601(raw) do
      {:ok, datetime, _offset} ->
        {:ok, datetime}

      {:error, :invalid_format} ->
        :error

      {:error, :invalid_date} ->
        {:error, "invalid date"}

      {:error, :invalid_time} ->
        {:error, "invalid time"}

      {:error, :missing_offset} ->
        {:error, "missing offset"}

      {:error, error} when is_atom(error) ->
        :error
    end
  end

  @impl Executive.Type
  def spec(_params) do
    quote do
      DateTime.t()
    end
  end
end
