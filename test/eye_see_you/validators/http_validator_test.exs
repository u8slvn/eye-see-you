defmodule EyeSeeYou.Validators.HttpValidatorTest do
  use EyeSeeYou.DataCase, async: true

  alias EyeSeeYou.Validators.HttpValidator

  describe "valid_http_method?/1" do
    test "returns true for standard HTTP methods" do
      assert HttpValidator.valid_http_method?("GET")
      assert HttpValidator.valid_http_method?("POST")
      assert HttpValidator.valid_http_method?("PUT")
      assert HttpValidator.valid_http_method?("PATCH")
      assert HttpValidator.valid_http_method?("DELETE")
      assert HttpValidator.valid_http_method?("HEAD")
      assert HttpValidator.valid_http_method?("OPTIONS")
    end

    test "returns false for non-standard methods" do
      refute HttpValidator.valid_http_method?("CONNECT")
      refute HttpValidator.valid_http_method?("TRACE")
      refute HttpValidator.valid_http_method?("CUSTOM")
    end

    test "returns false for lowercase methods" do
      refute HttpValidator.valid_http_method?("get")
      refute HttpValidator.valid_http_method?("post")
    end

    test "returns false for non-string values" do
      refute HttpValidator.valid_http_method?(nil)
      refute HttpValidator.valid_http_method?(123)
      refute HttpValidator.valid_http_method?([])
    end
  end

  describe "valid_headers?/1" do
    test "returns true for valid header lists" do
      assert HttpValidator.valid_headers?([
               %{"name" => "Content-Type", "value" => "application/json"},
               %{"name" => "Accept", "value" => "application/json"}
             ])

      assert HttpValidator.valid_headers?([])
    end

    test "returns false for headers missing name or value" do
      refute HttpValidator.valid_headers?([
               # missing value
               %{"name" => "Content-Type"}
             ])

      refute HttpValidator.valid_headers?([
               # missing name
               %{"value" => "application/json"}
             ])

      refute HttpValidator.valid_headers?([
               # empty map
               %{}
             ])
    end

    test "returns false for non-list values" do
      refute HttpValidator.valid_headers?(nil)
      refute HttpValidator.valid_headers?("not-a-list")
      refute HttpValidator.valid_headers?(%{})
    end
  end

  describe "validate_headers/2" do
    test "accepts valid headers" do
      changeset =
        %{
          headers: [
            %{"name" => "Content-Type", "value" => "application/json"}
          ]
        }
        |> changeset()
        |> HttpValidator.validate_headers(:headers)

      assert changeset.valid?
    end

    test "adds error for invalid headers" do
      changeset =
        %{
          headers: [
            %{"wrong" => "format"}
          ]
        }
        |> changeset()
        |> HttpValidator.validate_headers(:headers)

      refute changeset.valid?

      assert hd(errors_on(changeset).headers) ==
               "contains invalid headers - each header must have 'name' and 'value' fields"
    end

    test "adds error for non-list headers" do
      changeset =
        %{headers: "not-a-list"}
        |> changeset()
        |> HttpValidator.validate_headers(:headers)

      refute changeset.valid?
      assert hd(errors_on(changeset).headers) == "is invalid"
    end

    test "skips validation for nil values" do
      changeset =
        %{headers: nil}
        |> changeset()
        |> HttpValidator.validate_headers(:headers)

      assert changeset.valid?
    end

    test "works when field is not present in changeset" do
      changeset =
        %{}
        |> changeset()
        |> HttpValidator.validate_headers(:headers)

      assert changeset.valid?
    end
  end

  # Helper to create a basic changeset for testing
  defp changeset(attrs) do
    schema = %{headers: {:array, :map}}

    {%{}, schema}
    |> Ecto.Changeset.cast(attrs, Map.keys(schema))
  end
end
