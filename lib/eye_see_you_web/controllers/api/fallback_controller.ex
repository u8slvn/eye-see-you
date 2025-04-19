defmodule EyeSeeYouWeb.API.FallbackController do
  use EyeSeeYouWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: EyeSeeYouWeb.ErrorJSON)
    |> render(:error, changeset: changeset)
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(json: EyeSeeYouWeb.ErrorJSON)
    |> render(:"404")
  end
end
