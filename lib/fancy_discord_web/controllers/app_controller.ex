defmodule FancyDiscordWeb.AppController do
  use FancyDiscordWeb, :controller
  alias FancyDiscord.Schema.App
  alias FancyDiscord.Schema.User
  alias FancyDiscord.Deploy
  alias FancyDiscord.Utils
  alias FancyDiscordWeb.Plugs.CheckAppLimit
  alias FancyDiscordWeb.Plugs.CheckAppOwner

  plug CheckAppOwner when action not in [:create, :list]
  plug CheckAppLimit when action in [:create]

  def list(%{assigns: %{current_user: %User{} = user}} = conn, _) do
    apps =
      user
      |> User.with_apps()
      |> Map.fetch!(:apps)
    render(conn, "apps.json", %{apps: apps})
  end

  def create(%{assigns: %{current_user: %User{id: user_id} = user}} = conn, params) do
    with {:ok, %App{} = app} <- App.create(params, user_id) do
      render(conn, "app.json", %{app: app})
    else
      false ->
        conn
        |> put_status(403)
        |> json(%{errors: %{data: "You have too much apps"}})
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> json(%{errors: %{data: Utils.changeset_to_errors(changeset)}})
    end
  end

  def update(%{assigns: %{current_user: %User{id: user_id} = user}} = conn, %{"app_id" => id} = params) do
    %App{} = app = App.get(id)
    with {:ok, %App{} = app} <- App.update(app, params) do
      render(conn, "app.json", %{app: app})
    else
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> json(%{errors: %{data: Utils.changeset_to_errors(changeset)}})
    end
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
    %App{} = app = App.get_in_user(user, id)
    render(conn, "app.json", %{app: app, status: Deploy.app_status(%{app_id: id})})
  end
end
