defmodule EyeSeeYouWeb.API.SentinelController do
  use EyeSeeYouWeb, :controller

  alias EyeSeeYou.Sentinels
  alias EyeSeeYou.Sentinels.Sentinel

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
    with {:ok, %Sentinel{} = sentinel} <- Sentinels.Repository.create_sentinel(sentinel_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/sentinels/#{sentinel}")
      |> render(:show, sentinel: sentinel)
    end
  end
end
