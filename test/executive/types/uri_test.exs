defmodule Executive.Types.URITest do
  use ExUnit.Case, async: true
  alias Executive.Schema
  alias Executive.Types.URI, as: URIType
  doctest URIType

  describe "name/1" do
    test "URI" do
      assert URIType.name([]) == "URI"
    end
  end

  describe "parse/2" do
    test "can return string" do
      uri = "https://user:pass@example.com:12345/some/path?query=something#some-fragment"
      assert URIType.parse([as: :string], nil, uri) == {:ok, uri}
    end

    test "can return struct" do
      uri = "https://user:pass@example.com:12345/some/path?query=something#some-fragment"

      assert {:ok, %URI{} = struct} = URIType.parse([as: :struct], nil, uri)
      assert URI.to_string(struct) == uri
    end

    test "defaults to string" do
      uri = "https://example.com"
      assert URIType.parse([], nil, uri) == {:ok, uri}
    end

    test "error if invalid URI" do
      assert URIType.parse([], nil, "https://example.com>") == :error
    end

    test "requires scheme by default" do
      assert {:error, message} = URIType.parse([], nil, "//example.com")
      assert to_string(message) == "Missing URI scheme"
    end

    test "requires host by default" do
      assert {:error, message} = URIType.parse([], nil, "https://")
      assert to_string(message) == "Missing URI host"
    end

    test "can explicitly require scheme" do
      params = [require: [:scheme]]
      uri = "//example.com"
      assert {:error, message} = URIType.parse(params, nil, uri)
      assert to_string(message) == "Missing URI scheme"
    end

    test "can handle explicitly required scheme" do
      params = [require: [:scheme]]
      uri = "https://example.com"
      assert URIType.parse(params, nil, uri) == {:ok, uri}
    end

    test "can require userinfo" do
      params = [require: [:userinfo]]
      uri = "https://example.com"
      assert {:error, message} = URIType.parse(params, nil, uri)
      assert to_string(message) == "Missing URI userinfo"
    end

    test "can handle required userinfo" do
      params = [require: [:userinfo]]
      uri = "https://user:pass@example.com"
      assert URIType.parse(params, nil, uri) == {:ok, uri}
    end

    test "can explicitly require host" do
      params = [require: [:host]]
      uri = "https://"
      assert {:error, message} = URIType.parse(params, nil, uri)
      assert to_string(message) == "Missing URI host"
    end

    test "can handle explicitly required host" do
      params = [require: [:host]]
      uri = "https://example.com"
      assert URIType.parse(params, nil, uri) == {:ok, uri}
    end

    test "can require port" do
      params = [require: [:port]]
      uri = "//example.com"
      assert {:error, message} = URIType.parse(params, nil, uri)
      assert to_string(message) == "Missing URI port"
    end

    test "can handle required port" do
      params = [require: [:port]]
      uri = "//example.com:443"
      assert URIType.parse(params, nil, uri) == {:ok, uri}
    end

    test "port can be inferred from scheme" do
      params = [require: [:port]]
      uri = "https://example.com"
      assert URIType.parse(params, nil, uri) == {:ok, uri}
    end

    test "can require path" do
      params = [require: [:path]]
      uri = "https://example.com"
      assert {:error, message} = URIType.parse(params, nil, uri)
      assert to_string(message) == "Missing URI path"
    end

    test "can handle required path" do
      params = [require: [:path]]
      uri = "https://example.com/some/path"
      assert URIType.parse(params, nil, uri) == {:ok, uri}
    end

    test "can require query" do
      params = [require: [:query]]
      uri = "https://example.com"
      assert {:error, message} = URIType.parse(params, nil, uri)
      assert to_string(message) == "Missing URI query"
    end

    test "can handle required query" do
      params = [require: [:query]]
      uri = "https://example.com?some=query"
      assert URIType.parse(params, nil, uri) == {:ok, uri}
    end

    test "can require fragment" do
      params = [require: [:fragment]]
      uri = "https://example.com"
      assert {:error, message} = URIType.parse(params, nil, uri)
      assert to_string(message) == "Missing URI fragment"
    end

    test "can handle required fragment" do
      params = [require: [:fragment]]
      uri = "https://example.com#some-fragment"
      assert URIType.parse(params, nil, uri) == {:ok, uri}
    end

    test "can be missing several parts" do
      params = [require: [:scheme, :userinfo, :host, :port, :path, :query, :fragment]]
      uri = "https://example.com"
      assert {:error, message} = URIType.parse(params, nil, uri)
      assert to_string(message) == "Missing URI userinfo, path, query, fragment"
    end
  end

  describe "spec/1" do
    test "string" do
      assert URIType.spec(as: :string) == quote(do: String.t())
    end

    test "struct" do
      assert URIType.spec(as: :struct) == quote(do: URI.t())
    end
  end
end
