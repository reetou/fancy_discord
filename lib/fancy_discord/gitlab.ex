defmodule FancyDiscord.Gitlab do
  def trigger_token, do: Application.fetch_env!(:fancy_discord, :gitlab)[:trigger_token]
  def project_id, do: Application.fetch_env!(:fancy_discord, :gitlab)[:project_id]
  def project_access_token, do: Application.fetch_env!(:fancy_discord, :gitlab)[:project_access_token]

  def job(key) do
    Application.fetch_env!(:fancy_discord, :gitlab)[:jobs][key]
  end

  def webhook_secret_token(key) do
    Application.fetch_env!(:fancy_discord, :gitlab)[:webhook_secret_tokens][key]
  end
end
