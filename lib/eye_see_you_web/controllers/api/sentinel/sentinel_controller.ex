defmodule EyeSeeYouWeb.API.Sentinel.SentinelController do
  use EyeSeeYouWeb, :controller

  alias EyeSeeYou.Sentinels
  alias EyeSeeYou.Sentinels.Models.Sentinel

  action_fallback(EyeSeeYouWeb.API.FallbackController)

  def index(conn, _params) do
    sentinels = Sentinels.Repository.list_sentinels()
    render(conn, :index, sentinels: sentinels)
  end

  def show(conn, %{"uuid" => uuid}) do
    with {:ok, %Sentinel{} = sentinel} <- Sentinels.Repository.get_sentinel(uuid) do
      render(conn, :show, sentinel: sentinel)
    end
  end

  def create(conn, %{"sentinel" => sentinel_params}) do
    with {:ok, %Sentinel{} = sentinel} <- Sentinels.create_sentinel(sentinel_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/sentinels/#{sentinel.uuid}")
      |> render(:show, sentinel: sentinel)
    end
  end

  def update(conn, %{"uuid" => uuid, "sentinel" => sentinel_params}) do
    with {:ok, %Sentinel{} = sentinel} <- Sentinels.get_sentinel(uuid),
         {:ok, %Sentinel{} = updated_sentinel} <-
           Sentinels.update_sentinel(sentinel, sentinel_params) do
      render(conn, :show, sentinel: updated_sentinel)
    end
  end

  def delete(conn, %{"uuid" => uuid}) do
    with {:ok, %Sentinel{} = sentinel} <- Sentinels.get_sentinel(uuid),
         {:ok, %Sentinel{}} <- Sentinels.delete_sentinel(sentinel) do
      send_resp(conn, :no_content, "")
    end
  end
end
