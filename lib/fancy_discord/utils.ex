defmodule FancyDiscord.Utils do
  require Logger

  def handle_cmd_response({x, 0}) do
    Logger.debug("Successful command, stodut: #{inspect x}")
    :ok
  end
  def handle_cmd_response({msg, code}), do: {:error, %{code: code, message: msg}}

  def exec_cmd(bin, args) do
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

  defmacro is_uuid(value) do
    quote do
      is_binary(unquote(value)) and byte_size(unquote(value)) == 36 and
      binary_part(unquote(value), 8, 1) == "-" and binary_part(unquote(value), 13, 1) == "-" and
      binary_part(unquote(value), 18, 1) == "-" and binary_part(unquote(value), 23, 1) == "-"
    end
  end
end
