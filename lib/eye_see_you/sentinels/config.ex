defmodule EyeSeeYou.Sentinels.Config do
  @moduledoc """
  Configuration schemas for sentinels.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias EyeSeeYou.Sentinels.Config.SimpleHttpStatus

  @primary_key false
  embedded_schema do
    field(:type, :string, default: "simple_http_status")
    embeds_one(:data, SimpleHttpStatus, on_replace: :update)
  end

  def changeset(config, attrs) do
    type = attrs["type"] || attrs[:type] || "simple_http_status"

    config
    |> cast(attrs, [:type])
    |> validate_required([:type])
    |> validate_inclusion(:type, ["simple_http_status"],
      message: "must be a supported configuration type"
    )
    |> maybe_cast_data(attrs, type)
  end

  defp maybe_cast_data(changeset, _attrs, "simple_http_status") do
    changeset
    |> cast_embed(:data, with: &SimpleHttpStatus.changeset/2)
  end

  defp maybe_cast_data(changeset, _attrs, _invalid_type) do
    # Just return the changeset without casting the data in case of an invalid type
    changeset
  end
end

defmodule EyeSeeYou.Sentinels.Config.SimpleHttpStatus do
  @moduledoc """
  SimpleHttpStatus configuration type for monitoring HTTP endpoints.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:url, :string)
    field(:expected_status, :integer, default: 200)
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:url, :expected_status])
    |> validate_required([:url])
    |> validate_url(:url)
    |> validate_inclusion(:expected_status, 100..599,
      message: "must be a valid HTTP status code (100-599)"
    )
  end

  defp validate_url(changeset, field) do
    validate_change(changeset, field, fn _, url ->
      uri = URI.parse(url)

      if is_nil(uri.scheme) or is_nil(uri.host) or uri.scheme not in ["http", "https"] do
        [{field, "is not a valid HTTP URL"}]
      else
        []
      end
    end)
  end
end
