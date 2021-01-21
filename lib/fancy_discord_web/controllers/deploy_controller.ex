defmodule FancyDiscordWeb.DeployController do
  use FancyDiscordWeb, :controller
  alias FancyDiscord.Deploy
  alias FancyDiscord.Schema.Job
  alias FancyDiscord.Schema.App
  alias FancyDiscord.Schema.User
  alias FancyDiscordWeb.Plugs.CheckAppOwner
  alias FancyDiscordWeb.Plugs.CheckAvailableMachine
  alias FancyDiscordWeb.Plugs.CheckDeployLock

  plug CheckAppOwner
  plug CheckAvailableMachine when action in [:create, :init]
  plug CheckDeployLock when action in [:create, :init, :destroy]

  def logs(%{assigns: %{current_user: %User{} = user}} = conn, %{"app_id" => app_id}) do
    with %Job{logs: logs} <- Deploy.last_deploy_details(%{app_id: app_id}) do
      conn
      |> text(logs)
    else
      nil ->
        conn
        |> put_status(404)
        |> json(%{errors: %{data: "Not Found"}})
    end
  end

  def last_details(%{assigns: %{current_user: %User{} = user}} = conn, %{"app_id" => app_id}) do
    case Deploy.last_deploy_details(%{app_id: app_id}) do
      %Job{} = job ->
        render(conn, "job.json", %{job: job})
      nil ->
        conn
        |> put_status(404)
        |> json(%{errors: %{data: "No jobs yet."}})
    end
  end

  def init(%{assigns: %{current_user: %User{} = user}} = conn, %{"app_id" => app_id}) do
    case Deploy.init_app?(%{app_id: app_id}) do
      true ->
        case Deploy.start_init_job(%{app_id: app_id}) do
          %Job{} = job -> render(conn, "job.json", %{job: job})
          {:error, :no_available_machine} ->
            conn
            |> put_status(400)
            |> json(%{errors: %{data: "No available machine, try again later"}})
        end
      false ->
        conn
        |> put_status(400)
        |> json(%{errors: %{data: "App already initialized or cannot be initialized"}})
    end
  end

  def create(%{assigns: %{current_user: %User{} = user}} = conn, %{"app_id" => app_id}) do
    case Deploy.maybe_deploy(%{app_id: app_id}) do
      {:error, :no_available_machine} ->
        conn
        |> put_status(400)
        |> json(%{errors: %{data: "No available machine, try again later"}})
      {:error, :deploy_in_progress} ->
        conn
        |> put_status(400)
        |> json(%{errors: %{data: "App is still being initialized or there is a build in progress already"}})
      %Job{} = job -> render(conn, "job.json", %{job: job})
    end
  end

  def destroy(%{assigns: %{current_user: %User{} = user}} = conn, %{"app_id" => app_id}) do
    case App.get_in_user(user, app_id) do
      %App{id: id} = app ->
        {:ok, _} =
          id
          |> App.get()
          |> Deploy.kill_deploy()
        json(conn, %{})
      nil ->
        conn
        |> put_status(404)
        |> json(%{errors: %{data: "Not found"}})
    end
  end
end
