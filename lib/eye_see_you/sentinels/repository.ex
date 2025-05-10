defmodule EyeSeeYou.Sentinels.Repository do
  @moduledoc """
  The Sentinels Reposiotry.
  """

  import Ecto.Query, warn: false
  alias EyeSeeYou.Repo
  alias EyeSeeYou.Sentinels.Models.Sentinel

  @doc """
  Returns the list of sentinels.
  """
  def list_sentinels do
    Repo.all(Sentinel)
  end

  @doc """
  Gets a single sentinel.
  """
  def get_sentinel(uuid) when is_binary(uuid) do
    case Repo.get(Sentinel, uuid) do
      nil -> {:error, :not_found}
      sentinel -> {:ok, sentinel}
    end
  end

  @doc """
  Creates a sentinel.
  """
  def create_sentinel(attrs \\ %{}) do
    %Sentinel{}
    |> Sentinel.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a sentinel.
  """
  def update_sentinel(%Sentinel{} = sentinel, attrs) do
    sentinel
    |> Sentinel.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a sentinel.
  """
  def delete_sentinel(%Sentinel{} = sentinel) do
    Repo.delete(sentinel)
  end
end
