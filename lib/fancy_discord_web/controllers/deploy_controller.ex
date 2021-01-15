defmodule FancyDiscordWeb.DeployController do
  use FancyDiscordWeb, :controller
  alias FancyDiscord.Deploy
  alias FancyDiscord.Schema.Job

  def last_details(conn, %{"app_id" => app_id}) do
    case Deploy.last_job_details(%{app_id: app_id}) do
      %Job{} = job -> json(conn, job)
      nil ->
        conn
        |> put_status(404)
        |> json(%{errors: %{data: "No jobs. App was not initialized probably"}})
    end
  end

  def init(conn, %{"app_id" => app_id}) do
    case Deploy.init_app?(%{app_id: app_id}) do
      true ->
        job = Deploy.start_init_job(%{app_id: app_id})
        json(conn, job)
      false ->
        conn
        |> put_status(400)
        |> json(%{errors: %{data: "App already initialized or cannot be initialized"}})
    end
  end

  def create(conn, %{"app_id" => app_id}) do
    case Deploy.can_start_new?(%{app_id: app_id}) do
      true ->
        job = Deploy.start_deploy(%{app_id: app_id})
        json(conn, job)
      false ->
        conn
        |> put_status(400)
        |> json(%{errors: %{data: "App not initialized or there is a build in progress"}})
    end
  end
end
