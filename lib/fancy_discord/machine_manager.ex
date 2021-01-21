defmodule FancyDiscord.MachineManager do
  alias FancyDiscord.Schema.Machine
  alias FancyDiscord.Schema.App
  alias FancyDiscord.Repo

  def has_available? do
    not is_nil(Machine.first_available())
  end

  def available_machines do
    Machine.available_count()
  end

  def occupy_first_available(app) do
    Repo.transaction(fn ->
      case Machine.first_available() do
        nil -> Repo.rollback(:no_available_machine)
        %Machine{} = machine ->
          machine
          |> Machine.inc_deployed(1)
          |> App.assign_machine(app)
      end
    end)
    |> case do
         {:ok, app} -> app
         e -> e
       end
  end

  def release_machine(%App{} = app) do
    {:ok, _} = Repo.transaction(fn ->
      %App{machine: %Machine{ip: ip}} = App.with_machine(app)
      ip
      |> Machine.by_ip()
      |> Machine.inc_deployed(-1)
      App.reset_machine(app)
    end)
  end
end
