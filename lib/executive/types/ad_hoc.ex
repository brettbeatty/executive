defmodule Executive.Types.AdHoc do
  @moduledoc """
  Ad hoc options use 1-arity function params for one-off types.

  The function should handle analogues to all `Executive.Type` callbacks,
  depending on the value passed in.

  Argument        | Analogue
  --------------- | --------
  `:name`         | `c:Executive.Type.name/1`
  `{:parse, raw}` | `c:Executive.Type.parse/2`
  `:type_name`    | `c:Executive.Type.name/1`
  `:spec`         | `c:Executive.Type.spec/1`

  ## Examples
  If, for example, a mix task needed a base64-encoded option, that could be
  implemented with an ad hoc type instead of a custom type module.

      iex> alias Executive.Schema
      iex> base64 = fn
      ...>   :name ->
      ...>     "base64"
      ...>
      ...>   {:parse, raw} ->
      ...>     with :error <- Base.decode64(raw) do
      ...>       {:error, ["Expected type base64, got ", inspect(raw)]}
      ...>     end
      ...>
      ...>   :raw_type ->
      ...>     :string
      ...>
      ...>   :spec ->
      ...>     quote(do: binary())
      ...> end
      iex> Schema.new()
      ...> |> Schema.put_option(:my_option, {:ad_hoc, base64})
      ...> |> Schema.parse(["--my-option", "bXkgc3RyaW5n"])
      {:ok, [], [my_option: "my string"]}

  This type is aliased as `:ad_hoc`.
  """
  @behaviour Executive.Type

  @impl Executive.Type
  def name(fun) when is_function(fun, 1) do
    fun.(:name)
  end

  @impl Executive.Type
  def parse(fun, raw) when is_function(fun, 1) do
    fun.({:parse, raw})
  end

  @impl Executive.Type
  def raw_type(fun) when is_function(fun, 1) do
    fun.(:raw_type)
  end

  @impl Executive.Type
  def spec(fun) when is_function(fun, 1) do
    fun.(:spec)
  end
end
