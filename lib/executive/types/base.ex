defmodule Executive.Types.Base do
  @moduledoc """
  Base decodes strings of base 16, 32, or 64.

      iex> Schema.new()
      ...> |> Schema.put_option(:my_option, :base64)
      ...> |> Schema.parse(["--my-option", "bXkgc3RyaW5n"])
      {:ok, [], [my_option: "my string"]}

  ## Bases

  The following bases are supported:

  Base      | Underlying function
  --------- | -------------------
  `:"16"`   | `Base.decode16/2`
  `:"32"`   | `Base.decode32/2`
  `:"64"`   | `Base.decode64/2`
  `:url_64` | `Base.url_decode64/2`

  ## Options

  By default bases 16 and 32 can accept both upper and lowercase letters. This
  can be restricted by including a case with the base:

      iex> Schema.new()
      ...> |> Schema.put_option(:my_option, {:base16, case: :upper})
      ...> |> Schema.parse!(["--my-option", "6d7920737472696e67"])
      ** (Executive.ParseError) 1 error found!
      --my-option : Expected type uppercase base 16 string, got "6d7920737472696e67"

  By default bases 32, 64, and url_64 can accept both padded and unpadded
  strings. Padding can be required by including `padding: true` with the base.

      iex> Schema.new()
      ...> |> Schema.put_option(:my_option, {:base32, padding: true})
      ...> |> Schema.parse!(["--my-option", "NV4SA43UOJUW4ZY"])
      ** (Executive.ParseError) 1 error found!
      --my-option : Expected type padded base 32 string, got "NV4SA43UOJUW4ZY"

  ## Aliases

  This type is aliased as `:base`.

  Each base also has its own alias that can be parametrized with the options
  supported by that base.

  Alias                 | Type
  --------------------- | ----
  `:base16`             | `{:base, :"16"}`
  `{:base16, opts}`     | `{:base, {:"16", opts}}`
  `:base32`             | `{:base, :"32"}`
  `{:base32, opts}`     | `{:base, {:"32", opts}}`
  `:base64`             | `{:base, :"64"}`
  `{:base64, opts}`     | `{:base, {:"64", opts}}`
  `:url_base64`         | `{:base, :url_64}`
  `{:url_base64, opts}` | `{:base, {:url_64, opts}}`

  """
  @behaviour Executive.Type

  @typedoc """
  Type is parametrized with a base and opts specific to that base.

  See the module's "Bases" and "Options" sections.
  """
  @type params() ::
          :"16"
          | {:"16", case: Base.decode_case()}
          | :"32"
          | {:"32", case: Base.decode_case(), padding: boolean()}
          | :"64"
          | {:"64", padding: boolean()}
          | :url_64
          | {:url_64, padding: boolean()}

  @typep normalized_params() ::
           {:"16", Base.decode_case()}
           | {:"32", Base.decode_case(), boolean()}
           | {:"64", boolean()}
           | {:url_64, boolean()}

  @impl Executive.Type
  def name(params) do
    case normalize(params) do
      {:"16", case} ->
        case_name("base 16 string", case)

      {:"32", case, padding} ->
        "base 32 string"
        |> case_name(case)
        |> padding_name(padding)

      {:"64", padding} ->
        padding_name("base 64 string", padding)

      {:url_64, padding} ->
        padding_name("URL-safe base 64 string", padding)
    end
  end

  @spec case_name(IO.chardata(), Base.decode_case()) :: IO.chardata()
  defp case_name(name, case)
  defp case_name(name, :mixed), do: name
  defp case_name(name, :upper), do: ["uppercase ", name]
  defp case_name(name, :lower), do: ["lowercase ", name]

  @spec padding_name(IO.chardata(), boolean()) :: IO.chardata()
  defp padding_name(name, padding)
  defp padding_name(name, true), do: ["padded ", name]
  defp padding_name(name, false), do: name

  @impl Executive.Type
  def parse(params, raw) do
    case normalize(params) do
      {:"16", case} ->
        Base.decode16(raw, case: case)

      {:"32", case, padding} ->
        Base.decode32(raw, case: case, padding: padding)

      {:"64", padding} ->
        Base.decode64(raw, padding: padding)

      {:url_64, padding} ->
        Base.url_decode64(raw, padding: padding)
    end
  end

  @impl Executive.Type
  def spec(_params) do
    quote do
      binary()
    end
  end

  @spec normalize(params()) :: normalized_params()
  defp normalize(params)

  defp normalize({:"16", opts}) do
    {:"16", Keyword.get(opts, :case, :mixed)}
  end

  defp normalize({:"32", opts}) do
    {:"32", Keyword.get(opts, :case, :mixed), Keyword.get(opts, :padding, false)}
  end

  defp normalize({:"64", opts}) do
    {:"64", Keyword.get(opts, :padding, false)}
  end

  defp normalize({:url_64, opts}) do
    {:url_64, Keyword.get(opts, :padding, false)}
  end

  defp normalize(params) when is_atom(params) do
    normalize({params, []})
  end
end
