defmodule FancyDiscord.Deploy do
  alias FancyDiscord
  alias FancyDiscord.Schema.App
  alias FancyDiscord.Schema.Machine
  alias FancyDiscord.Schema.Job
  alias FancyDiscord.Repo
  alias FancyDiscord.Gitlab
  alias FancyDiscord.MachineManager
  require Logger

  @destroy_job_name Gitlab.job(:destroy_dokku_app)

  def start_init_job(%{app_id: app_id}) do
    app_id
    |> App.get()
    |> IO.inspect(label: "BEFORE assign")
    |> maybe_assign_machine()
    |> IO.inspect(label: "At assign")
    |> FancyDiscord.create_bot()
    |> case do
         %{
           "id" => id,
           "status" => status,
           "name" => name,
           "created_at" => created,
           "finished_at" => finished,
           "pipeline" => %{
             "id" => pipeline_id
           }
         } ->
           {:ok, job} = Job.create(%{
             gitlab_job_id: id,
             gitlab_pipeline_id: pipeline_id,
             status: status,
             name: name,
             created_at: created,
             finished_at: finished,
             app_id: app_id
           })
           job
         x ->
           IO.inspect(x, label: "Error")
       end
  end

  def start_deploy(%{app_id: app_id}) do
    %{
      "id" => id,
      "status" => status,
      "name" => name,
      "created_at" => created,
      "finished_at" => finished,
      "pipeline" => %{
        "id" => pipeline_id
      }
    } =
      app_id
      |> App.get()
      |> maybe_assign_machine()
      |> FancyDiscord.deploy_bot()
    {:ok, job} = Job.create(%{
      gitlab_job_id: id,
      gitlab_pipeline_id: pipeline_id,
      status: status,
      name: name,
      created_at: created,
      finished_at: finished,
      app_id: app_id
    })
    job
  end

  def maybe_assign_machine(%App{machine: nil} = app) do
    app
    |> MachineManager.occupy_first_available()
    |> IO.inspect(label: "After occupy")
    |> App.with_machine()
  end

  def maybe_assign_machine(%App{machine: %Machine{}} = app) do
    app
  end

  def last_job_details(%{app_id: app_id}) do
    Job.last_created(app_id)
  end

  def last_deploy_details(%{app_id: app_id}) do
    Job.last_deploy(app_id)
  end

  def can_start_new?(%{app_id: app_id}) do
    init_job_name = Gitlab.job(:create_dokku_app)
    case Job.last_created(app_id) |> IO.inspect(label: "Last created") do
      nil -> true
      %Job{status: status, name: ^init_job_name} when status in ["success"] -> true
      %Job{status: status, name: name} when name != init_job_name and status not in ["running", "pending"] -> true
      _ -> false
    end
  end

  def maybe_deploy(%{app_id: app_id}) do
    case can_start_new?(%{app_id: app_id}) do
      true ->
        try do
          start_deploy(%{app_id: app_id})
        rescue
          e in MatchError -> {:error, :no_available_machine}
        end
      false -> {:error, :deploy_in_progress}
    end
  end

  def init_app?(%{app_id: app_id} = data) do
    case App.get(app_id) do
      %App{machine_id: nil} -> true
      %App{machine_id: machine_id} when not is_nil(machine_id) -> true
    end
  end

  def can_create_init_job?(%{app_id: app_id}) do
    init_job_name = Gitlab.job(:create_dokku_app)
    case Job.last_created(app_id) do
      nil -> true
      %Job{status: status, name: name} when name == init_job_name and status in ["canceled", "failed"] -> true
      _ -> false
    end
  end

  def refresh_job_status(pipeline_id, name) do
    [gitlab_pipeline_id: pipeline_id, name: name]
    |> Job.get_by()
    |> refresh_job_status()
  end

  def refresh_job_status(%Job{gitlab_pipeline_id: pipeline_id, name: name, id: id}) do
    %{
      "status" => status,
      "finished_at" => finished
    } = Gitlab.Job.get_job(pipeline_id, name)
    %Job{} =
      Job.update(id, %{status: status, finished_at: finished})
      |> maybe_update_app_deploy_date()
  end

  def maybe_update_app_deploy_date(%Job{status: "success", app_id: app_id, name: name} = job) when name != @destroy_job_name do
    App.deploy_update(app_id)
    job
  end

  def maybe_update_app_deploy_date(x), do: x

  def refresh_active_jobs do
    Job.active_jobs()
    |> Enum.map(&refresh_job_status/1)
  end

  def kill_old_deploys do
    App.last_deployed_apps()
    |> Enum.map(&kill_deploy/1)
  end

  def kill_deploy(%App{id: app_id, machine_id: machine_id} = app) do
    with %{
           "id" => id,
           "status" => status,
           "name" => name,
           "created_at" => created,
           "finished_at" => finished,
           "pipeline" => %{
             "id" => pipeline_id
           }
         } = gitlab_job <- FancyDiscord.destroy_bot(app),
         MachineManager.release_machine(app) do
      Job.create(%{
        gitlab_job_id: id,
        gitlab_pipeline_id: pipeline_id,
        status: status,
        name: name,
        created_at: created,
        finished_at: finished,
        app_id: app_id
      })
      {:ok, gitlab_job}
    else
      e ->
        Logger.error("Cannot kill deploy: #{inspect e}")
        {:error, :cannot_kill_deploy}
    end
  end

  def reset_host_by_job(%{gitlab_job_id: gitlab_job_id}) do
    with %Job{app_id: app_id} <- Job.get_by(gitlab_job_id: gitlab_job_id),
         %App{} = app <- App.get(app_id) do
      %App{} = App.reset_machine(app)
    else
      nil -> {:error, :not_found}
    end
  end

  def gitlab_job_status_update(%{"id" => id, "pipeline" => %{"id" => pipeline_id}, "name" => name}) do
    destroy_app_job_name = Gitlab.job(:destroy_dokku_app)
    case name do
      name when destroy_app_job_name == name ->
        reset_host_by_job(%{gitlab_job_id: id})
      name ->
        refresh_job_status(pipeline_id, name)
    end
  end
end
