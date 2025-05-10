defmodule EyeSeeYou.Sentinels.Models.Sentinel do
  @moduledoc """
  Represents a sentinel that monitors a specific HTTP endpoint.
  A sentinel periodically checks the URL and verifies the response.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias EyeSeeYou.Sentinels.Models.Config

  @status_values [:active, :paused, :error]

  def status_values, do: @status_values

  @primary_key {:uuid, :binary_id, autogenerate: true}
  schema "sentinels" do
    field(:name, :string)
    field(:interval, :integer, default: 60)
    field(:status, Ecto.Enum, values: @status_values, default: :active)
    embeds_one(:config, Config, on_replace: :update)

    timestamps()
  end

  def changeset(sentinel, attrs) do
    sentinel
    |> cast(attrs, [:name, :interval])
    |> validate_required([:name])
    |> validate_number(:interval,
      greater_than: 0,
      message: "must be a valid positive integer greater than 0"
    )
    |> cast_embed(:config, required: true)
  end
end

defimpl Phoenix.Param, for: EyeSeeYou.Sentinels.Sentinel do
  def to_param(%{uuid: uuid}), do: "#{uuid}"
end
