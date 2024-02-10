defmodule Executive.Types.URI do
  @moduledoc """
  URI parses from a URI string.

      iex> Schema.new()
      ...> |> Schema.put_option(:my_option, :uri)
      ...> |> Schema.parse(["--my-option", "https://example.com"])
      {:ok, [], [my_option: "https://example.com"]}

  This type uses `URI.new/1` under the hood.

  ## Options

  The following options are supported:

    - `:as` - one of `:string` (default) or `:struct`
      - `:string` validated URI given as a string

            iex> Schema.new()
            ...> |> Schema.put_option(:my_option, {:uri, as: :string})
            ...> |> Schema.parse(["--my-option", "https://example.com"])
            {:ok, [], [my_option: "https://example.com"]}

      - `:struct` parsed URI returned as `URI` struct

            iex> Schema.new()
            ...> |> Schema.put_option(:my_option, {:uri, as: :struct})
            ...> |> Schema.parse(["--my-option", "https://example.com"])
            {:ok, [], [my_option: %URI{scheme: "https", host: "example.com", port: 443}]}

    - `:require` - a list of URI parts required in the URI
      - default is `[:scheme, :host]`
      - can include any keys in `URI` struct

  This type is aliased as `:uri`.
  """
  @behaviour Executive.Type

  @typedoc """
  Params this type can accept.
  """
  @type params() :: [as: :string | :struct, require: [part()]]

  @typedoc """
  URI parts that can be required.

  See `URI.__struct__/0`.
  """
  @type part() :: :fragment | :host | :path | :port | :query | :scheme | :userinfo

  @impl Executive.Type
  def name(_params) do
    "URI"
  end

  @impl Executive.Type
  def parse(params, raw) do
    with {:ok, parsed} <- parse_uri(raw),
         :ok <- require_parts(parsed, params) do
      {:ok, format(parsed, raw, params)}
    end
  end

  @spec parse_uri(String.t()) :: {:ok, URI.t()} | :error
  defp parse_uri(raw) do
    with {:error, _character} <- URI.new(raw) do
      :error
    end
  end

  @spec require_parts(URI.t(), params()) :: :ok | {:error, IO.chardata()}
  defp require_parts(uri, params) do
    required = Keyword.get(params, :require, [:scheme, :host])

    case Enum.reject(required, &present?(uri, &1)) do
      [] ->
        :ok

      missing ->
        missing
        |> Enum.map(&Atom.to_string/1)
        |> Enum.intersperse(", ")
        |> then(&{:error, ["Missing URI " | &1]})
    end
  end

  @spec present?(URI.t(), part()) :: boolean()
  defp present?(uri, part)

  defp present?(uri, :port) do
    match?(%URI{port: port} when port in 0..65_535, uri)
  end

  defp present?(uri, part) do
    match?(%{^part => value} when byte_size(value) > 0, uri)
  end

  @spec format(URI.t(), String.t(), params()) :: String.t() | URI.t()
  defp format(struct, string, params) do
    case Keyword.get(params, :as, :string) do
      :string -> string
      :struct -> struct
    end
  end

  @impl Executive.Type
  def spec(params) do
    case Keyword.get(params, :as, :string) do
      :string -> quote(do: String.t())
      :struct -> quote(do: URI.t())
    end
  end
end
