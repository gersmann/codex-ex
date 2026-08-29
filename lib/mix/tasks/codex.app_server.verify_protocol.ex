defmodule Mix.Tasks.Codex.AppServer.VerifyProtocol do
  @shortdoc "Verifies Codex app-server generated protocol files are up to date"

  @moduledoc """
  Regenerates the Codex app-server protocol modules into a temporary directory and
  fails if the committed generated files have drifted from the current schema snapshot.

  ## Usage

      mix codex.app_server.verify_protocol [options]

  ## Options

    * `--schema-root` - Schema snapshot root. Defaults to `priv/schema`.
    * `--generated-path` - Generated Elixir path. Defaults to `lib/codex_ex/app_server/protocol/generated`.
    * `--help`, `-h` - Show this help
  """

  use Mix.Task

  alias CodexEx.AppServer.Protocol.Verifier

  @impl Mix.Task
  def run(args) do
    {opts, _argv, _invalid} =
      OptionParser.parse(args,
        aliases: [h: :help],
        strict: [schema_root: :string, generated_path: :string, help: :boolean]
      )

    if opts[:help] do
      Mix.shell().info(@moduledoc)
    else
      verify_opts =
        Enum.reject(
          [
            schema_root: opts[:schema_root],
            generated_path: opts[:generated_path]
          ],
          fn {_key, value} -> is_nil(value) end
        )

      case Verifier.verify(verify_opts) do
        {:ok, %{file_count: file_count, generated_path: generated_path}} ->
          Mix.shell().info("Verified #{file_count} Codex app-server generated files at #{generated_path}")

        {:error, {:drift_detected, drifts}} ->
          Mix.raise("""
          Codex app-server generated protocol drift detected.

          #{format_drifts(drifts)}

          Run `mix codex.app_server.generate_protocol` and commit the updated generated files.
          """)

        {:error, {:invalid_schema_root, schema_root}} ->
          Mix.raise("Schema root does not exist: #{schema_root}")

        {:error, {:schema_read_failed, path, reason}} ->
          Mix.raise("Failed to read schema file #{path}: #{inspect(reason)}")

        {:error, {:schema_decode_failed, path, reason}} ->
          Mix.raise("Failed to decode schema file #{path}: #{inspect(reason)}")

        {:error, {:write_failed, path, reason}} ->
          Mix.raise("Failed while regenerating protocol files at #{path}: #{inspect(reason)}")
      end
    end
  end

  defp format_drifts(drifts) do
    Enum.map_join(drifts, "\n", fn
      {:missing_file, path} -> "  missing: #{path}"
      {:unexpected_file, path} -> "  unexpected: #{path}"
      {:changed_file, path} -> "  changed: #{path}"
    end)
  end
end
