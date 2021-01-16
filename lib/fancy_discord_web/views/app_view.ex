defmodule FancyDiscordWeb.AppView do
  use FancyDiscordWeb, :view
  alias FancyDiscord.Schema.App

  # If you want to customize a particular status code
  # for a certain format, you may uncomment below.
  # def render("500.html", _assigns) do
  #   "Internal Server Error"
  # end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.html" becomes
  # "Not Found".
  def render("apps.json", %{apps: apps}) do
    %{apps: App.fill_virtual_fields(apps)}
  end

  def render("app.json", %{app: app}) do
    %{app: App.fill_virtual_fields(app)}
  end
end
