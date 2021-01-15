defmodule FancyDiscord.Deploy do
  alias FancyDiscord
  alias FancyDiscord.Schema.App
  alias FancyDiscord.Schema.Job
  alias FancyDiscord.Gitlab

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

  def can_init?(%{app_id: app_id}) do
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
end
