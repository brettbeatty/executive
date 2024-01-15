defmodule Executive.Types.BaseTest do
  use ExUnit.Case, async: true
  alias Executive.Schema
  alias Executive.Types.Base, as: BaseType
  doctest BaseType

  describe "name/1" do
    test "base 16" do
      name = BaseType.name(:"16")
      assert to_string(name) == "hex-encoded string"
    end

    test "uppercase base 16" do
      name = BaseType.name({:"16", case: :upper})
      assert to_string(name) == "uppercase hex-encoded string"
    end

    test "lowercase base 16" do
      name = BaseType.name({:"16", case: :lower})
      assert to_string(name) == "lowercase hex-encoded string"
    end

    test "base 32" do
      name = BaseType.name(:"32")
      assert to_string(name) == "base 32 string"
    end

    test "uppercase base 32" do
      name = BaseType.name({:"32", case: :upper})
      assert to_string(name) == "uppercase base 32 string"
    end

    test "lowercase base 32" do
      name = BaseType.name({:"32", case: :lower})
      assert to_string(name) == "lowercase base 32 string"
    end

    test "padded base 32" do
      name = BaseType.name({:"32", padding: true})
      assert to_string(name) == "padded base 32 string"
    end

    test "padded uppercase base 32" do
      name = BaseType.name({:"32", case: :upper, padding: true})
      assert to_string(name) == "padded uppercase base 32 string"
    end

    test "padded lowercase base 32" do
      name = BaseType.name({:"32", case: :lower, padding: true})
      assert to_string(name) == "padded lowercase base 32 string"
    end

    test "base 64" do
      name = BaseType.name(:"64")
      assert to_string(name) == "base 64 string"
    end

    test "padded base 64" do
      name = BaseType.name({:"64", padding: true})
      assert to_string(name) == "padded base 64 string"
    end

    test "URL-safe base 64" do
      name = BaseType.name(:url_64)
      assert to_string(name) == "URL-safe base 64 string"
    end

    test "padded URL-safe base 64" do
      name = BaseType.name({:url_64, padding: true})
      assert to_string(name) == "padded URL-safe base 64 string"
    end
  end

  describe "parse/3" do
    test "base 16 handles uppercase" do
      decoded = :crypto.strong_rand_bytes(4)
      encoded = Base.encode16(decoded, case: :upper)
      params = :"16"

      assert BaseType.parse(params, nil, encoded) == {:ok, decoded}
    end

    test "base 16 handles lowercase" do
      decoded = :crypto.strong_rand_bytes(4)
      encoded = Base.encode16(decoded, case: :lower)
      params = :"16"

      assert BaseType.parse(params, nil, encoded) == {:ok, decoded}
    end

    test "base 16 can be restricted to uppercase" do
      decoded = :crypto.strong_rand_bytes(4)
      encoded = Base.encode16(decoded, case: :lower)
      params = {:"16", case: :upper}

      assert BaseType.parse(params, nil, encoded) == :error
    end

    test "base 16 handles required uppercase" do
      decoded = :crypto.strong_rand_bytes(4)
      encoded = Base.encode16(decoded, case: :upper)
      params = {:"16", case: :upper}

      assert BaseType.parse(params, nil, encoded) == {:ok, decoded}
    end

    test "base 16 can be restricted to lowercase" do
      decoded = :crypto.strong_rand_bytes(4)
      encoded = Base.encode16(decoded, case: :upper)
      params = {:"16", case: :lower}

      assert BaseType.parse(params, nil, encoded) == :error
    end

    test "base 16 handles required lowercase" do
      decoded = :crypto.strong_rand_bytes(4)
      encoded = Base.encode16(decoded, case: :lower)
      params = {:"16", case: :lower}

      assert BaseType.parse(params, nil, encoded) == {:ok, decoded}
    end

    test "base 32 handles uppercase" do
      decoded = :crypto.strong_rand_bytes(5)
      encoded = Base.encode32(decoded, case: :upper)
      params = :"32"

      assert BaseType.parse(params, nil, encoded) == {:ok, decoded}
    end

    test "base 32 handles lowercase" do
      decoded = :crypto.strong_rand_bytes(5)
      encoded = Base.encode32(decoded, case: :lower)
      params = :"32"

      assert BaseType.parse(params, nil, encoded) == {:ok, decoded}
    end

    test "base 32 can be restricted to uppercase" do
      decoded = :crypto.strong_rand_bytes(5)
      encoded = Base.encode32(decoded, case: :lower)
      params = {:"32", case: :upper}

      assert BaseType.parse(params, nil, encoded) == :error
    end

    test "base 32 handles required uppercase" do
      decoded = :crypto.strong_rand_bytes(5)
      encoded = Base.encode32(decoded, case: :upper)
      params = {:"32", case: :upper}

      assert BaseType.parse(params, nil, encoded) == {:ok, decoded}
    end

    test "base 32 can be restricted to lowercase" do
      decoded = :crypto.strong_rand_bytes(5)
      encoded = Base.encode32(decoded, case: :upper)
      params = {:"32", case: :lower}

      assert BaseType.parse(params, nil, encoded) == :error
    end

    test "base 32 handles required lowercase" do
      decoded = :crypto.strong_rand_bytes(5)
      encoded = Base.encode32(decoded, case: :lower)
      params = {:"32", case: :lower}

      assert BaseType.parse(params, nil, encoded) == {:ok, decoded}
    end

    test "base 32 handles padded" do
      decoded = :crypto.strong_rand_bytes(4)
      encoded = Base.encode32(decoded)
      params = :"32"

      assert String.ends_with?(encoded, "=")
      assert BaseType.parse(params, nil, encoded) == {:ok, decoded}
    end

    test "base 32 handles unpadded" do
      decoded = :crypto.strong_rand_bytes(4)
      encoded = Base.encode32(decoded, padding: false)
      params = :"32"

      refute String.ends_with?(encoded, "=")
      assert BaseType.parse(params, nil, encoded) == {:ok, decoded}
    end

    test "base 32 can require padding" do
      decoded = :crypto.strong_rand_bytes(4)
      encoded = Base.encode32(decoded, padding: false)
      params = {:"32", padding: true}

      refute String.ends_with?(encoded, "=")
      assert BaseType.parse(params, nil, encoded) == :error
    end

    test "base 32 can handle required padding" do
      decoded = :crypto.strong_rand_bytes(4)
      encoded = Base.encode32(decoded)
      params = {:"32", padding: true}

      assert String.ends_with?(encoded, "=")
      assert BaseType.parse(params, nil, encoded) == {:ok, decoded}
    end

    test "base 64 handles padded" do
      decoded = :crypto.strong_rand_bytes(5)
      encoded = Base.encode64(decoded)
      params = :"64"

      assert String.ends_with?(encoded, "=")
      assert BaseType.parse(params, nil, encoded) == {:ok, decoded}
    end

    test "base 64 handles unpadded" do
      decoded = :crypto.strong_rand_bytes(5)
      encoded = Base.encode64(decoded, padding: false)
      params = :"64"

      refute String.ends_with?(encoded, "=")
      assert BaseType.parse(params, nil, encoded) == {:ok, decoded}
    end

    test "base 64 can require padding" do
      decoded = :crypto.strong_rand_bytes(5)
      encoded = Base.encode64(decoded, padding: false)
      params = {:"64", padding: true}

      refute String.ends_with?(encoded, "=")
      assert BaseType.parse(params, nil, encoded) == :error
    end

    test "base 64 handles required padding" do
      decoded = :crypto.strong_rand_bytes(5)
      encoded = Base.encode64(decoded)
      params = {:"64", padding: true}

      assert String.ends_with?(encoded, "=")
      assert BaseType.parse(params, nil, encoded) == {:ok, decoded}
    end

    test "URL 64 handles padded" do
      decoded = :crypto.strong_rand_bytes(5)
      encoded = Base.url_encode64(decoded)
      params = :url_64

      assert String.ends_with?(encoded, "=")
      assert BaseType.parse(params, nil, encoded) == {:ok, decoded}
    end

    test "URL 64 handles unpadded" do
      decoded = :crypto.strong_rand_bytes(5)
      encoded = Base.url_encode64(decoded, padding: false)
      params = :url_64

      refute String.ends_with?(encoded, "=")
      assert BaseType.parse(params, nil, encoded) == {:ok, decoded}
    end

    test "URL 64 can require padding" do
      decoded = :crypto.strong_rand_bytes(5)
      encoded = Base.url_encode64(decoded, padding: false)
      params = {:url_64, padding: true}

      refute String.ends_with?(encoded, "=")
      assert BaseType.parse(params, nil, encoded) == :error
    end

    test "URL 64 handles required padding" do
      decoded = :crypto.strong_rand_bytes(5)
      encoded = Base.url_encode64(decoded)
      params = {:url_64, padding: true}

      assert String.ends_with?(encoded, "=")
      assert BaseType.parse(params, nil, encoded) == {:ok, decoded}
    end
  end

  describe "spec/1" do
    test "binary" do
      assert BaseType.spec(:"64") == quote(do: binary())
    end
  end
end
