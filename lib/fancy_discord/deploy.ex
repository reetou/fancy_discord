defmodule FancyDiscord.Deploy do
  alias FancyDiscord
  alias FancyDiscord.Schema.App
  alias FancyDiscord.Schema.Job
  alias FancyDiscord.Gitlab
  require Logger

  def start_init_job(%{app_id: app_id}) do
    %App{} = app = App.get(app_id)
    %{
      "id" => id,
      "status" => status,
      "name" => name,
      "created_at" => created,
      "finished_at" => finished,
      "pipeline" => %{
        "id" => pipeline_id
      }
    } = FancyDiscord.create_bot(app)
    {:ok, job} = Job.create(%{
      gitlab_job_id: id,
      gitlab_pipeline_id: pipeline_id,
      status: status,
      name: name,
      created_at: created,
      finished_at: finished
    })
    job
  end

  def start_deploy(%{app_id: app_id}) do
    %App{} = app = App.get(app_id)
    %{
      "id" => id,
      "status" => status,
      "name" => name,
      "created_at" => created,
      "finished_at" => finished,
      "pipeline" => %{
        "id" => pipeline_id
      }
    } = FancyDiscord.deploy_bot(app)
    {:ok, job} = Job.create(%{
      gitlab_job_id: id,
      gitlab_pipeline_id: pipeline_id,
      status: status,
      name: name,
      created_at: created,
      finished_at: finished
    })
    job
  end

  def last_job_details(%{app_id: app_id}) do
    Job.last_created(app_id)
  end

  def can_start_new?(%{app_id: app_id}) do
    init_job_name = Gitlab.job(:create_dokku_app)
    case Job.last_created(app_id) do
      %Job{status: status, name: ^init_job_name} when status in ["success"] -> true
      %Job{status: status, name: name} when name != init_job_name and status not in ["running", "pending"] -> true
      _ -> false
    end
  end

  def init_app?(%{app_id: app_id} = data) do
    with %App{dokku_host: dokku_host} <- App.get(app_id),
        nil <- dokku_host do
      can_create_init_job?(data)
    else
      _ -> false
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
    %Job{gitlab_pipeline_id: ^pipeline_id, name: ^name, id: id} = Job.get_by(gitlab_pipeline_id: pipeline_id, name: name)
    %{
      "status" => status,
      "finished_at" => finished
    } = Gitlab.Job.get_job(pipeline_id, name)
    %Job{} = Job.update(id, %{status: status, finished_at: finished})
  end

  def kill_deploy(%{app_id: app_id}) do
    with %App{dokku_host: dokku_host} = app when not is_nil(dokku_host) <- App.get(app_id),
         %{} = gitlab_job <- Gitlab.Job.start_build(app, Gitlab.job(:destroy_dokku_app)) do
      {:ok, gitlab_job}
    else
      e ->
        Logger.error("Cannot kill deploy: #{inspect e}")
        {:error, :cannot_kill_deploy}
    end
  end

  def reset_host_by_job(%{gitlab_job_id: gitlab_job_id}) do
    with %Job{app_id: app_id} <- Job.get_by(gitlab_job_id: gitlab_job_id),
         %App{} <- App.get(app_id) do
      %App{} = App.reset_dokku_host(app_id)
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
