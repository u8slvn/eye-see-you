defmodule EyeSeeYou.Validators.JsonValidatorTest do
  use EyeSeeYou.DataCase, async: true

  alias EyeSeeYou.Validators.JsonValidator

  describe "valid_json?/1" do
    test "returns true for valid JSON objects" do
      assert JsonValidator.valid_json?(~s({"name":"John","age":30}))
      assert JsonValidator.valid_json?(~s({}))
      assert JsonValidator.valid_json?(~s({"nested":{"key":"value"}}))
    end

    test "returns true for valid JSON arrays" do
      assert JsonValidator.valid_json?(~s([1,2,3]))
      assert JsonValidator.valid_json?(~s([]))
      assert JsonValidator.valid_json?(~s([{"name":"John"},{"name":"Jane"}]))
    end

    test "returns true for valid JSON primitives" do
      assert JsonValidator.valid_json?(~s("string"))
      assert JsonValidator.valid_json?(~s(123))
      assert JsonValidator.valid_json?(~s(true))
      assert JsonValidator.valid_json?(~s(false))
      assert JsonValidator.valid_json?(~s(null))
    end

    test "returns false for invalid JSON" do
      # missing quotes around key
      refute JsonValidator.valid_json?(~s({name:"John"}))
      # trailing comma
      refute JsonValidator.valid_json?(~s({"name":"John",}))
      # missing value
      refute JsonValidator.valid_json?(~s({"name":}))
      # trailing comma
      refute JsonValidator.valid_json?(~s([1,2,]))
      refute JsonValidator.valid_json?("not json at all")
    end

    test "returns false for nil or empty strings" do
      refute JsonValidator.valid_json?(nil)
      refute JsonValidator.valid_json?("")
    end
  end

  describe "validate_json/2" do
    test "accepts valid JSON" do
      changeset =
        %{payload: ~s({"name":"John"})}
        |> changeset()
        |> JsonValidator.validate_json(:payload)

      assert changeset.valid?
    end

    test "adds error for invalid JSON" do
      changeset =
        %{payload: ~s({invalid json})}
        |> changeset()
        |> JsonValidator.validate_json(:payload)

      refute changeset.valid?
      assert hd(errors_on(changeset).payload) =~ "is not valid JSON:"
    end

    test "skips validation for nil values" do
      changeset =
        %{payload: nil}
        |> changeset()
        |> JsonValidator.validate_json(:payload)

      assert changeset.valid?
    end

    test "skips validation for empty string" do
      changeset =
        %{payload: ""}
        |> changeset()
        |> JsonValidator.validate_json(:payload)

      assert changeset.valid?
    end

    test "works when field is not present in changeset" do
      changeset =
        %{}
        |> changeset()
        |> JsonValidator.validate_json(:payload)

      assert changeset.valid?
    end
  end

  # Helper to create a basic changeset for testing
  defp changeset(attrs) do
    schema = %{payload: :string}

    {%{}, schema}
    |> Ecto.Changeset.cast(attrs, Map.keys(schema))
  end
end
