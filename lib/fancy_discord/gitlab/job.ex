defmodule FancyDiscord.Gitlab.Job do
  alias FancyDiscord.Gitlab
  require Logger

  defp headers() do
    [
      {"Content-Type", "application/json"},
      {"PRIVATE-TOKEN", Gitlab.project_access_token()}
    ]
  end

  defp extract_body({:ok, %HTTPoison.Response{status_code: code, body: body}})
       when code in [200, 201] do
    Jason.decode!(body)
  end

  defp extract_body({:ok, response}) do
    Logger.error("Unexpected response: #{inspect response}")
    {:error, response}
  end

  defp pipeline_body(%{variables: variables}) do
    Jason.encode!(%{
      token: Gitlab.trigger_token(),
      ref: "master",
      variables: variables
    })
  end

  def start_build(%{} = data, job_name)  do
    data
    |> create_pipeline()
    |> get_job(job_name)
    |> play_job()
    |> IO.inspect(label: "Result")
  end

  def create_pipeline(%{} = data) do
    "https://gitlab.com/api/v4/projects/#{Gitlab.project_id()}/pipeline"
    |> HTTPoison.post(pipeline_body(data), headers())
    |> extract_body()
  end

  def get_job(%{"id" => pipeline_id}, name) do
    "https://gitlab.com/api/v4/projects/#{Gitlab.project_id()}/pipelines/#{pipeline_id}/jobs"
    |> HTTPoison.get(headers())
    |> extract_body()
    |> extract_job(name)
  end

  def get_job(pipeline_id, name) do
    "https://gitlab.com/api/v4/projects/#{Gitlab.project_id()}/pipelines/#{pipeline_id}/jobs"
    |> HTTPoison.get(headers())
    |> extract_body()
    |> extract_job(name)
  end

  def extract_job(jobs, name) when is_list(jobs) do
    jobs
    |> Enum.find(fn %{"name" => job_name} ->
      job_name === name
    end)
    |> IO.inspect(label: "Extracted job")
  end

  def play_job(%{"id" => job_id}) do
    "https://gitlab.com/api/v4/projects/#{Gitlab.project_id()}/jobs/#{job_id}/play"
    |> HTTPoison.post("", headers())
    |> extract_body()
  end
end
