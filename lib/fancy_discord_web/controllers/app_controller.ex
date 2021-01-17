defmodule FancyDiscordWeb.AppController do
  use FancyDiscordWeb, :controller
  alias FancyDiscord.Schema.App
  alias FancyDiscord.Schema.User
  alias FancyDiscord.Deploy
  alias FancyDiscord.Utils

  def list(%{assigns: %{current_user: %User{} = user}} = conn, _) do
    apps =
      user
      |> User.with_apps()
      |> Map.fetch!(:apps)
    render(conn, "apps.json", %{apps: apps})
  end

  def create(%{assigns: %{current_user: %User{id: user_id} = user}} = conn, params) do
    with %User{app_limit: limit, apps: apps} <- User.with_apps(user),
         true <- length(apps) < limit,
         {:ok, %App{} = app} <- App.create(params, user_id) do
      Task.start(fn ->
        Deploy.start_init_job(%{app_id: app.id})
      end)
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
      %App{} = app ->
        render(conn, "app.json", %{app: app})
      nil ->
        conn
        |> put_status(404)
        |> json(%{errors: %{data: "Not found"}})
    end
  end
end
