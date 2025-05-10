defmodule EyeSeeYou.Validators.UrlValidatorTest do
  use EyeSeeYou.DataCase, async: true

  alias EyeSeeYou.Validators.UrlValidator

  describe "valid_http_url?/1" do
    test "returns true for valid HTTP URLs" do
      assert UrlValidator.valid_http_url?("http://example.com")
      assert UrlValidator.valid_http_url?("https://example.com")
      assert UrlValidator.valid_http_url?("http://localhost:4000")
      assert UrlValidator.valid_http_url?("https://api.example.com/v1/users")
      assert UrlValidator.valid_http_url?("http://example.com/path?query=value")
    end

    test "returns false for URLs with invalid schemes" do
      refute UrlValidator.valid_http_url?("ftp://example.com")
      refute UrlValidator.valid_http_url?("file:///etc/hosts")
      refute UrlValidator.valid_http_url?("ws://example.com")
    end

    test "returns false for malformed URLs" do
      # missing scheme
      refute UrlValidator.valid_http_url?("example.com")
      # missing host
      refute UrlValidator.valid_http_url?("http://")
      # single slash
      refute UrlValidator.valid_http_url?("http:/example.com")
      # missing scheme
      refute UrlValidator.valid_http_url?("://example.com")
    end

    test "returns false for non-string values" do
      refute UrlValidator.valid_http_url?(nil)
      refute UrlValidator.valid_http_url?(123)
      refute UrlValidator.valid_http_url?([])
    end
  end

  describe "validate_http_url/2" do
    test "accepts valid HTTP URLs" do
      changeset =
        %{url: "https://example.com"}
        |> changeset()
        |> UrlValidator.validate_http_url(:url)

      assert changeset.valid?
    end

    test "adds error for invalid URLs" do
      changeset =
        %{url: "example.com"}
        |> changeset()
        |> UrlValidator.validate_http_url(:url)

      refute changeset.valid?
      assert "is not a valid HTTP URL" in errors_on(changeset).url
    end

    test "adds error for non-HTTP URLs" do
      changeset =
        %{url: "ftp://example.com"}
        |> changeset()
        |> UrlValidator.validate_http_url(:url)

      refute changeset.valid?
      assert "is not a valid HTTP URL" in errors_on(changeset).url
    end

    test "works when field is not present in changeset" do
      changeset =
        %{}
        |> changeset()
        |> UrlValidator.validate_http_url(:url)

      assert changeset.valid?
    end
  end

  # Helper to create a basic changeset for testing
  defp changeset(attrs) do
    schema = %{url: :string}

    {%{}, schema}
    |> Ecto.Changeset.cast(attrs, Map.keys(schema))
  end
end
