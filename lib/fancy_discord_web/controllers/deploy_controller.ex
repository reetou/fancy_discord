defmodule FancyDiscordWeb.DeployController do
  use FancyDiscordWeb, :controller
  alias FancyDiscord.Deploy
  alias FancyDiscord.Schema.Job
  alias FancyDiscord.Schema.App
  alias FancyDiscord.Schema.User

  def last_details(%{assigns: %{current_user: %User{} = user}} = conn, %{"app_id" => app_id}) do
    case Deploy.last_job_details(%{app_id: app_id}) do
      %Job{} = job ->
        render(conn, "job.json", %{job: job})
      nil ->
        conn
        |> put_status(404)
        |> json(%{errors: %{data: "No jobs. App was not initialized probably"}})
    end
  end

  def init(%{assigns: %{current_user: %User{} = user}} = conn, %{"app_id" => app_id}) do
    case Deploy.init_app?(%{app_id: app_id}) do
      true ->
        job = Deploy.start_init_job(%{app_id: app_id})
        render(conn, "job.json", %{job: job})
      false ->
        conn
        |> put_status(400)
        |> json(%{errors: %{data: "App already initialized or cannot be initialized"}})
    end
  end

  def create(%{assigns: %{current_user: %User{} = user}} = conn, %{"app_id" => app_id}) do
    case Deploy.can_start_new?(%{app_id: app_id}) do
      true ->
        job = Deploy.start_deploy(%{app_id: app_id})
        render(conn, "job.json", %{job: job})
      false ->
        conn
        |> put_status(400)
        |> json(%{errors: %{data: "App not initialized or there is a build in progress"}})
    end
  end

  def destroy(%{assigns: %{current_user: %User{} = user}} = conn, %{"app_id" => app_id}) do
    case App.get_in_user(user, app_id) do
      %App{} ->
        {:ok, _} = Deploy.kill_deploy(%{app_id: app_id})
        json(conn, %{})
      nil ->
        conn
        |> put_status(404)
        |> json(%{errors: %{data: "Not found"}})
    end
  end
end
