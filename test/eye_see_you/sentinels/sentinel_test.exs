defmodule EyeSeeYou.Sentinels.SentinelTest do
  use ExUnit.Case
  alias EyeSeeYou.Sentinels.Sentinel

  describe "Sentinel.changeset" do
    test "creates a valid changeset with proper attributes" do
      attrs = %{name: "API Test", url: "https://example.com/api"}
      changeset = Sentinel.changeset(%Sentinel{}, attrs)

      assert changeset.valid?
    end

    test "sets default values when not provided" do
      attrs = %{name: "API Test", url: "https://example.com/api"}
      changeset = Sentinel.changeset(%Sentinel{}, attrs)

      # Get the changes map to see what would be inserted
      changes = changeset.changes

      # Default values should not be in changes since they're schema defaults
      refute Map.has_key?(changes, :interval)
      refute Map.has_key?(changes, :expected_status)
    end

    test "validates required fields" do
      # Missing name
      changeset = Sentinel.changeset(%Sentinel{}, %{url: "https://example.com"})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name

      # Missing url
      changeset = Sentinel.changeset(%Sentinel{}, %{name: "API Test"})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).url
    end

    test "validates url format" do
      # Invalid URL (missing scheme)
      changeset =
        Sentinel.changeset(%Sentinel{}, %{
          name: "API Test",
          url: "example.com"
        })

      refute changeset.valid?
      assert "is not a valid HTTP URL" in errors_on(changeset).url

      # Invalid URL (wrong scheme)
      changeset =
        Sentinel.changeset(%Sentinel{}, %{
          name: "API Test",
          url: "ftp://example.com"
        })

      refute changeset.valid?
      assert "is not a valid HTTP URL" in errors_on(changeset).url
    end

    test "allows customizing interval and expected_status" do
      attrs = %{
        name: "API Test",
        url: "https://example.com/api",
        interval: 30,
        expected_status: 201
      }

      changeset = Sentinel.changeset(%Sentinel{}, attrs)

      assert changeset.valid?
      assert changeset.changes.interval == 30
      assert changeset.changes.expected_status == 201
    end
  end

  # Helper function to extract errors from a changeset
  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
