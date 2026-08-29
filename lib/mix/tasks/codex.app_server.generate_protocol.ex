defmodule Mix.Tasks.Codex.AppServer.GenerateProtocol do
  @shortdoc "Generates Elixir protocol modules from the committed Codex app-server schema"

  @moduledoc """
  Generates Elixir protocol structs and codecs from the committed Codex app-server
  JSON Schema snapshot.

  ## Usage

      mix codex.app_server.generate_protocol [options]

  ## Options

    * `--schema-root` - Schema snapshot root. Defaults to `priv/schema`.
    * `--output` - Generated Elixir output path. Defaults to `lib/codex_ex/app_server/protocol/generated`.
    * `--help`, `-h` - Show this help

  ## Examples

      mix codex.app_server.generate_protocol
      mix codex.app_server.generate_protocol --output tmp/codex_protocol
  """

  use Mix.Task

  alias CodexEx.AppServer.Protocol.Generator

  @impl Mix.Task
  def run(args) do
    {opts, _argv, _invalid} =
      OptionParser.parse(args,
        aliases: [h: :help],
        strict: [schema_root: :string, output: :string, help: :boolean]
      )

    if opts[:help] do
      Mix.shell().info(@moduledoc)
    else
      generate_opts =
        Enum.reject(
          [
            schema_root: opts[:schema_root],
            output_path: opts[:output]
          ],
          fn {_key, value} -> is_nil(value) end
        )

      case Generator.generate(generate_opts) do
        {:ok, %{file_count: file_count, output_path: output_path}} ->
          Mix.shell().info("Generated #{file_count} Codex app-server protocol files into #{output_path}")

        {:error, {:invalid_schema_root, schema_root}} ->
          Mix.raise("Schema root does not exist: #{schema_root}")

        {:error, {:schema_read_failed, path, reason}} ->
          Mix.raise("Failed to read schema file #{path}: #{inspect(reason)}")

        {:error, {:schema_decode_failed, path, reason}} ->
          Mix.raise("Failed to decode schema file #{path}: #{inspect(reason)}")

        {:error, {:write_failed, path, reason}} ->
          Mix.raise("Failed to write generated protocol file #{path}: #{inspect(reason)}")
      end
    end
  end
end
