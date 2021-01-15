defmodule FancyDiscordWeb.AppController do
  use FancyDiscordWeb, :controller
  alias FancyDiscord.Schema.App
  alias FancyDiscord.Utils

  def create(conn, params) do
    case App.create(params) do
      {:ok, %App{} = app} -> json(conn, app)
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> json(%{errors: %{data: Utils.changeset_to_errors(changeset)}})
    end
  end

  def delete(conn, %{"app_id" => id}) do
    App.delete(id)
    json(conn, %{})
  end

  def show(conn, %{"app_id" => id}) do
    case App.get(id) do
      %App{} = app -> json(conn, app)
      nil ->
        conn
        |> put_status(404)
        |> json(%{errors: %{data: "Not found"}})
    end
  end
end
