defmodule Mix.Tasks.Codex.AppServer.SnapshotSchema do
  @shortdoc "Snapshots Codex app-server JSON Schema into the repo"

  @moduledoc """
  Runs `codex app-server generate-json-schema --experimental` and snapshots the
  exported schema bundle into a tracked repo directory.

  ## Usage

      mix codex.app_server.snapshot_schema [options]

  ## Options

    * `--codex` - Path to the codex executable. Defaults to the first `codex` on `$PATH`.
    * `--output` - Snapshot destination path. Defaults to `priv/schema`.
    * `--help`, `-h` - Show this help

  ## Examples

      mix codex.app_server.snapshot_schema
      mix codex.app_server.snapshot_schema --codex ~/.local/bin/codex
      mix codex.app_server.snapshot_schema --output tmp/codex_app_server_schema
  """

  use Mix.Task

  alias CodexEx.AppServer.SchemaSnapshot

  @impl Mix.Task
  def run(args) do
    {opts, _argv, _invalid} =
      OptionParser.parse(args,
        aliases: [h: :help],
        strict: [codex: :string, output: :string, help: :boolean]
      )

    if opts[:help] do
      Mix.shell().info(@moduledoc)
    else
      snapshot_opts =
        Enum.reject(
          [
            executable: opts[:codex],
            output_path: opts[:output]
          ],
          fn {_key, value} -> is_nil(value) end
        )

      case SchemaSnapshot.snapshot(snapshot_opts) do
        {:ok, %{file_count: file_count, output_path: output_path}} ->
          Mix.shell().info("Snapshotted #{file_count} Codex app-server schema files to #{output_path}")

        {:error, :codex_executable_not_found} ->
          Mix.raise("Could not find a `codex` executable. Pass --codex or install codex locally.")

        {:error, {:snapshot_command_failed, exit_status, output}} ->
          Mix.raise("""
          `codex app-server generate-json-schema` failed with exit status #{exit_status}.

          #{output}
          """)

        {:error, {:canonicalize_failed, path, reason}} ->
          Mix.raise("Failed to canonicalize schema snapshot #{path}: #{inspect(reason)}")

        {:error, {:snapshot_copy_failed, reason}} ->
          Mix.raise("Failed to copy schema snapshot into the repo: #{inspect(reason)}")
      end
    end
  end
end
