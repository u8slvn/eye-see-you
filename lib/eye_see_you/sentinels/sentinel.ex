defmodule EyeSeeYou.Sentinels.Sentinel do
  @moduledoc """
  Represents a sentinel that monitors a specific HTTP endpoint.
  A sentinel periodically checks the URL and verifies the response.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:uuid, :binary_id, autogenerate: true}
  schema "sentinels" do
    field(:name, :string)
    field(:url, :string)
    field(:interval, :integer, default: 60)
    field(:expected_status, :integer, default: 200)

    timestamps()
  end

  def changeset(sentinel, attrs) do
    sentinel
    |> cast(attrs, [:name, :url, :interval, :expected_status])
    |> validate_required([:name, :url])
    |> validate_url(:url)
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

defimpl Phoenix.Param, for: EyeSeeYou.Sentinels.Sentinel do
  def to_param(%{uuid: uuid}) do
    "#{uuid}"
  end
end
