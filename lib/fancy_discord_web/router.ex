defmodule FancyDiscordWeb.Router do
  use FancyDiscordWeb, :router
  alias FancyDiscordWeb.Plugs.GitlabSecretTokenPlug

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :gitlab_webhook do
    plug GitlabSecretTokenPlug
  end

  scope "/", FancyDiscordWeb do
    pipe_through :api

    post "/apps", AppController, :create
    delete "/apps/:app_id", AppController, :delete
    get "/apps/:app_id", AppController, :show

    post "/apps/:app_id/deploys", DeployController, :create
    post "/apps/:app_id/deploys/init", DeployController, :init
    get "/apps/:app_id/deploys/last", DeployController, :last_details
  end

  scope "/webhooks/gitlab", FancyDiscordWeb do
    pipe_through :api
    pipe_through :gitlab_webhook
    post "/job_status_update", GitlabController, :job_status_update
  end

  # Other scopes may use custom stacks.
  # scope "/api", FancyDiscordWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: FancyDiscordWeb.Telemetry
    end
  end
end
