defmodule FancyDiscord.Utils do
  require Logger

  def handle_cmd_response({x, 0}) do
    Logger.debug("Successful command, stodut: #{inspect x}")
    :ok
  end
  def handle_cmd_response({msg, code}), do: {:error, %{code: code, message: msg}}

  def exec_cmd(bin, args, opts \\ []) do
    Logger.debug("Executing #{bin} #{Enum.join(args, " ")}...")
    [bin | args]
    |> Enum.join(" ")
    |> String.to_charlist()
    |> :os.cmd()
    |> IO.inspect(label: "Result")
  end

  def changeset_to_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
