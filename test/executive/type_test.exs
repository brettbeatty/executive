defmodule Executive.TypeTest do
  use ExUnit.Case, async: true
  alias Executive.Type

  @type alias() ::
          :base
          | :base16
          | :base32
          | :base64
          | :boolean
          | :date
          | :datetime
          | :enum
          | :float
          | :integer
          | :naive_datetime
          | :neg_integer
          | :non_neg_integer
          | :pos_integer
          | :string
          | :time
          | :uri
          | :url_base64
          | :uuid

  describe "unalias/2" do
    test "alias :base" do
      params = make_ref()
      assert Type.unalias(:base, params) == {Executive.Types.Base, params}
    end

    test "alias :base16" do
      params = make_ref()
      assert Type.unalias(:base16, params) == {Executive.Types.Base, {:"16", params}}
    end

    test "alias :base32" do
      params = make_ref()
      assert Type.unalias(:base32, params) == {Executive.Types.Base, {:"32", params}}
    end

    test "alias :base64" do
      params = make_ref()
      assert Type.unalias(:base64, params) == {Executive.Types.Base, {:"64", params}}
    end

    test "alias :boolean" do
      params = make_ref()
      assert Type.unalias(:boolean, params) == {Executive.Types.Boolean, params}
    end

    test "alias :date" do
      params = make_ref()
      assert Type.unalias(:date, params) == {Executive.Types.Date, params}
    end

    test "alias :datetime" do
      params = make_ref()
      assert Type.unalias(:datetime, params) == {Executive.Types.DateTime, params}
    end

    test "alias :enum" do
      params = make_ref()
      assert Type.unalias(:enum, params) == {Executive.Types.Enum, params}
    end

    test "alias :float" do
      params = make_ref()
      assert Type.unalias(:float, params) == {Executive.Types.Float, params}
    end

    test "alias :integer" do
      params = make_ref()
      assert Type.unalias(:integer, params) == {Executive.Types.Integer, params}
    end

    test "alias :naive_datetime" do
      params = make_ref()
      assert Type.unalias(:naive_datetime, params) == {Executive.Types.NaiveDateTime, params}
    end

    test "alias :neg_integer" do
      assert Type.unalias(:neg_integer, make_ref()) == {Executive.Types.Integer, max: -1}
    end

    test "alias :non_neg_integer" do
      assert Type.unalias(:non_neg_integer, make_ref()) == {Executive.Types.Integer, min: 0}
    end

    test "alias :pos_integer" do
      assert Type.unalias(:pos_integer, make_ref()) == {Executive.Types.Integer, min: 1}
    end

    test "alias :string" do
      params = make_ref()
      assert Type.unalias(:string, params) == {Executive.Types.String, params}
    end

    test "alias :time" do
      params = make_ref()
      assert Type.unalias(:time, params) == {Executive.Types.Time, params}
    end

    test "alias :uri" do
      params = make_ref()
      assert Type.unalias(:uri, params) == {Executive.Types.URI, params}
    end

    test "alias :url_base64" do
      params = make_ref()
      assert Type.unalias(:url_base64, params) == {Executive.Types.Base, {:url_64, params}}
    end

    test "alias :uuid" do
      params = make_ref()
      assert Type.unalias(:uuid, params) == {Executive.Types.UUID, params}
    end

    test "module names" do
      params = make_ref()
      assert Type.unalias(MyType, params) == {MyType, params}
    end
  end
end
