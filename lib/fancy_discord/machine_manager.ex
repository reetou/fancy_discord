defmodule FancyDiscord.MachineManager do
  alias FancyDiscord.Schema.Machine
  alias FancyDiscord.Schema.App
  alias FancyDiscord.Repo

  def occupy_first_available(app) do
    {:ok, _} = Repo.transaction(fn ->
      Machine.first_available()
      |> Machine.inc_deployed(1)
      |> App.assign_machine(app)
    end)
  end

  def release_machine(app, ip) do
    {:ok, _} = Repo.transaction(fn ->
      ip
      |> Machine.by_ip()
      |> Machine.inc_deployed(-1)
      App.reset_machine(app)
    end)
  end
end
