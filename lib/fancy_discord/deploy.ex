defmodule FancyDiscord.Deploy do
  alias FancyDiscord
  alias FancyDiscord.Schema.App
  alias FancyDiscord.Schema.Machine
  alias FancyDiscord.Schema.Job
  alias FancyDiscord.Repo
  alias FancyDiscord.Gitlab
  alias FancyDiscord.MachineManager
  alias FancyDiscord.DeployLocker
  require Logger

  @destroy_job_name Gitlab.job(:destroy_dokku_app)

  def start_init_job(%{app_id: app_id}) do
    :ok = DeployLocker.lock(app_id)
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
    :ok = DeployLocker.lock(app_id)
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

  def app_status(%{app_id: app_id}) do
    init_job_name = Gitlab.job(:create_dokku_app)
    destroy_job_name = Gitlab.job(:destroy_dokku_app)
    case Job.last_created(app_id) do
      nil -> :init_required
      %Job{status: status, name: ^destroy_job_name} when status in ["success"] -> :init_required
      %Job{status: "failed", name: ^init_job_name} -> :init_failed
      %Job{status: status, name: ^init_job_name} when status in ["running", "pending"] -> :init_in_progress
      %Job{status: status, name: ^init_job_name} when status in ["success"] -> :init_success
      %Job{status: status, name: ^destroy_job_name} when status in ["running", "pending"] -> :destroy_in_progress
      %Job{status: status, name: name} when name != init_job_name and status in ["running", "pending"] -> :deploy_in_progress
      _ -> :free
    end
  end

  def last_deploy_details(%{app_id: app_id}) do
    Job.last_deploy(app_id)
  end

  def can_start_new?(%{app_id: app_id}) do
    init_job_name = Gitlab.job(:create_dokku_app)
    case Job.last_created(app_id) do
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
      |> store_logs()
      |> maybe_unlock()
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
    :ok = DeployLocker.lock(app_id)
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

  def gitlab_job_status_update(%{"id" => id, "pipeline" => %{"id" => pipeline_id}, "name" => name}) do
    destroy_app_job_name = Gitlab.job(:destroy_dokku_app)
    refresh_job_status(pipeline_id, name)
  end

  def store_logs(%Job{id: id} = job) do
    case extract_logs(job) do
      logs when is_binary(logs) ->
        Job.update(id, %{logs: logs})
      e ->
        Logger.error("Cannot get logs #{inspect e}")
        job
    end
    job
  end

  def extract_logs(%Job{gitlab_job_id: id} = job) do
    case Gitlab.Job.job_logs(id) do
      x when is_binary(x) ->
        x
        |> String.split("\n")
        |> filter_logs()
        |> Enum.slice(-10..-1)
        |> Enum.join("\n")
      x -> x
    end
  end

  def filter_logs([]), do: ""

  def filter_logs(logs) do
    Enum.filter(logs, &filter_log_line/1)
  end

  def filter_log_line("remote:" <> _), do: true
  def filter_log_line(_), do: false

  def maybe_unlock(%Job{app_id: app_id, status: status} = job) when status in ["canceled", "success", "failed"] do
    :ok = DeployLocker.unlock(app_id)
    job
  end

  def maybe_unlock(%Job{} = job), do: job
end
