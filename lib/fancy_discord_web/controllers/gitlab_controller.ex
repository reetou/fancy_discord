defmodule FancyDiscordWeb.GitlabController do
  use FancyDiscordWeb, :controller
  alias FancyDiscord.Deploy

  def job_status_update(conn, job) do
    IO.inspect(job, label: "Job")
    case Deploy.gitlab_job_status_update(job) do
      {:ok, _} -> json(conn, %{})
      {:error, _} ->
        conn
        |> put_status(400)
        |> json(%{})
    end
  end
end
