defmodule EyeSeeYou.Sentinels.Models.Config do
  @moduledoc """
  Configuration schemas for sentinels.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias EyeSeeYou.Sentinels.Models.Config.HttpRequest

  @primary_key false
  embedded_schema do
    field(:type, :string, default: "http_request")
    embeds_one(:data, HttpRequest, on_replace: :update)
  end

  def changeset(config, attrs) do
    type = attrs["type"] || attrs[:type] || "http_request"

    config
    |> cast(attrs, [:type])
    |> validate_required([:type])
    |> validate_inclusion(:type, ["http_request"],
      message: "must be a supported configuration type"
    )
    |> maybe_cast_data(attrs, type)
  end

  defp maybe_cast_data(changeset, _attrs, "http_request") do
    changeset
    |> cast_embed(:data, with: &HttpRequest.changeset/2)
  end

  defp maybe_cast_data(changeset, _attrs, _invalid_type) do
    changeset
  end
end

defmodule EyeSeeYou.Sentinels.Models.Config.HttpRequest do
  @moduledoc """
  HttpRequest configuration type for monitoring HTTP endpoints.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias EyeSeeYou.Validators.{HttpValidator, JsonValidator, UrlValidator}

  @primary_key false
  embedded_schema do
    field(:url, :string)
    field(:method, :string, default: "GET")
    field(:headers, {:array, :map}, default: [])
    field(:payload, :string)
    field(:expected_status, :integer, default: 200)
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:url, :method, :headers, :payload, :expected_status])
    |> validate_required([:url])
    |> UrlValidator.validate_http_url(:url)
    |> validate_inclusion(:method, HttpValidator.http_methods(),
      message: "must be a valid HTTP method"
    )
    |> HttpValidator.validate_headers(:headers)
    |> JsonValidator.validate_json(:payload)
    |> validate_inclusion(:expected_status, 100..599,
      message: "must be a valid HTTP status code (100-599)"
    )
  end
end
