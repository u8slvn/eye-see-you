defmodule EyeSeeYou.Sentinels.SentinelTest do
  use ExUnit.Case
  alias EyeSeeYou.Sentinels.Sentinel

  describe "Sentinel.changeset" do
    test "creates a valid changeset with proper attributes" do
      attrs = %{
        name: "API Test",
        config: %{
          type: "simple_http_status",
          data: %{
            url: "https://example.com/api",
            expected_status: 200
          }
        }
      }

      changeset = Sentinel.changeset(%Sentinel{}, attrs)

      assert changeset.valid?
    end

    test "sets default values when not provided" do
      attrs = %{
        name: "API Test",
        config: %{
          type: "simple_http_status",
          data: %{url: "https://example.com/api"}
        }
      }

      changeset = Sentinel.changeset(%Sentinel{}, attrs)

      changes = changeset.changes
      refute Map.has_key?(changes, :interval)

      config_changes = changes.config.changes
      data_changes = config_changes.data.changes
      refute Map.has_key?(data_changes, :expected_status)
    end

    test "validates required fields" do
      # Missing name
      changeset =
        Sentinel.changeset(%Sentinel{}, %{
          config: %{
            type: "simple_http_status",
            data: %{url: "https://example.com"}
          }
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name

      # Missing config
      changeset = Sentinel.changeset(%Sentinel{}, %{name: "API Test"})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).config

      # Missing url in config data
      changeset =
        Sentinel.changeset(%Sentinel{}, %{
          name: "API Test",
          config: %{
            type: "simple_http_status",
            data: %{}
          }
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).config.data.url
    end

    test "validates url format" do
      # Invalid URL (missing scheme)
      changeset =
        Sentinel.changeset(%Sentinel{}, %{
          name: "API Test",
          config: %{
            type: "simple_http_status",
            data: %{url: "example.com"}
          }
        })

      refute changeset.valid?
      assert "is not a valid HTTP URL" in errors_on(changeset).config.data.url

      # Invalid URL (wrong scheme)
      changeset =
        Sentinel.changeset(%Sentinel{}, %{
          name: "API Test",
          config: %{
            type: "simple_http_status",
            data: %{url: "ftp://example.com"}
          }
        })

      refute changeset.valid?
      assert "is not a valid HTTP URL" in errors_on(changeset).config.data.url
    end

    test "allows customizing interval and expected_status" do
      attrs = %{
        name: "API Test",
        interval: 30,
        config: %{
          type: "simple_http_status",
          data: %{
            url: "https://example.com/api",
            expected_status: 201
          }
        }
      }

      changeset = Sentinel.changeset(%Sentinel{}, attrs)

      assert changeset.valid?
      assert changeset.changes.interval == 30
      assert changeset.changes.config.changes.data.changes.expected_status == 201
    end

    test "validates configuration type" do
      changeset =
        Sentinel.changeset(%Sentinel{}, %{
          name: "API Test",
          config: %{
            type: "invalid_type",
            data: %{url: "https://example.com"}
          }
        })

      refute changeset.valid?
      assert "must be a supported configuration type" in errors_on(changeset).config.type
    end

    test "validates expected_status is a valid HTTP status code" do
      changeset =
        Sentinel.changeset(%Sentinel{}, %{
          name: "API Test",
          config: %{
            type: "simple_http_status",
            data: %{
              url: "https://example.com",
              expected_status: 999
            }
          }
        })

      refute changeset.valid?

      assert "must be a valid HTTP status code (100-599)" in errors_on(changeset).config.data.expected_status
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
