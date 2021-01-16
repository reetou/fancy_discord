defmodule FancyDiscordWeb.AppController do
  use FancyDiscordWeb, :controller
  alias FancyDiscord.Schema.App
  alias FancyDiscord.Schema.User
  alias FancyDiscord.Utils

  def create(%{assigns: %{current_user: %User{id: user_id, app_limit: limit, apps: apps}}} = conn, params) when length(apps) < limit do
    case App.create(params, user_id) do
      {:ok, %App{} = app} -> json(conn, app)
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> json(%{errors: %{data: Utils.changeset_to_errors(changeset)}})
    end
  end

  def create(conn, _) do
    conn
    |> put_status(403)
    |> json(%{errors: %{data: "You have too much apps. Try deleting one"}})
  end

  def delete(%{assigns: %{current_user: %User{} = user}} = conn, %{"app_id" => id}) do
    case App.get_in_user(user, id) do
      %App{} -> json(conn, %{})
      nil ->
        conn
        |> put_status(404)
        |> json(%{errors: %{data: "Not found"}})
    end
  end

  def show(%{assigns: %{current_user: %User{} = user}} = conn, %{"app_id" => id}) do
    case App.get_in_user(user, id) do
      %App{} = app -> json(conn, app)
      nil ->
        conn
        |> put_status(404)
        |> json(%{errors: %{data: "Not found"}})
    end
  end
end
