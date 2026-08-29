defmodule CodexEx.AppServer.SchemaSnapshot do
  @moduledoc false

  @type result ::
          {:ok, %{file_count: non_neg_integer(), output_path: Path.t()}}
          | {:error, :codex_executable_not_found}
          | {:error, {:remove_failed, Path.t(), term()}}
          | {:error, {:snapshot_command_failed, term(), binary()}}
          | {:error, {:canonicalize_failed, Path.t(), term()}}
          | {:error, {:snapshot_copy_failed, term()}}

  @spec snapshot(keyword()) :: result()
  def snapshot(opts \\ []) do
    output_path = opts |> Keyword.get(:output_path, default_output_path()) |> Path.expand()
    executable = Keyword.get(opts, :executable) || System.find_executable("codex")
    tmp_path = temporary_snapshot_path()

    try do
      with {:ok, executable} <- validate_executable(executable),
           :ok <- remove_path(tmp_path),
           :ok <- File.mkdir_p(tmp_path),
           {:ok, _output} <- export_schema(executable, tmp_path),
           :ok <- canonicalize_combined_schemas(tmp_path),
           :ok <- replace_snapshot(tmp_path, output_path) do
        {:ok, %{file_count: count_files(output_path), output_path: output_path}}
      end
    after
      File.rm_rf(tmp_path)
    end
  end

  defp validate_executable(executable) when is_binary(executable) and executable != "" do
    {:ok, executable}
  end

  defp validate_executable(_), do: {:error, :codex_executable_not_found}

  defp export_schema(executable, output_path) do
    args = ["app-server", "generate-json-schema", "--experimental", "--out", output_path]

    case System.cmd(executable, args, stderr_to_stdout: true) do
      {output, 0} ->
        {:ok, output}

      {output, exit_status} ->
        {:error, {:snapshot_command_failed, exit_status, output}}
    end
  rescue
    error in ErlangError ->
      {:error, {:snapshot_command_failed, error.original, Exception.message(error)}}
  end

  defp replace_snapshot(source_path, output_path) do
    output_parent = Path.dirname(output_path)

    with :ok <- File.mkdir_p(output_parent),
         :ok <- remove_path(output_path) do
      case File.cp_r(source_path, output_path) do
        {:ok, _paths} -> :ok
        {:error, reason, _path} -> {:error, {:snapshot_copy_failed, reason}}
      end
    end
  end

  defp canonicalize_combined_schemas(output_path) do
    output_path
    |> Path.join("*.schemas.json")
    |> Path.wildcard()
    |> Enum.reduce_while(:ok, fn path, :ok ->
      case canonicalize_json_file(path) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, {:canonicalize_failed, path, reason}}}
      end
    end)
    |> case do
      :ok -> :ok
      {:error, {:canonicalize_failed, _path, _reason}} = error -> error
    end
  end

  defp canonicalize_json_file(path) do
    with {:ok, json} <- File.read(path) do
      canonical =
        json
        |> Jason.decode!(objects: :ordered_objects)
        |> canonicalize_definitions()
        |> Jason.encode!(pretty: true)

      File.write(path, [canonical, "\n"])
    end
  rescue
    error in [Jason.DecodeError, Jason.EncodeError] -> {:error, error}
  end

  defp canonicalize_definitions(%Jason.OrderedObject{} = schema) do
    update_in(schema["definitions"].values, &Enum.sort_by(&1, fn {name, _value} -> name end))
  end

  defp count_files(output_path) do
    output_path
    |> Path.join("**/*")
    |> Path.wildcard(match_dot: true)
    |> Enum.count(&File.regular?/1)
  end

  defp temporary_snapshot_path do
    suffix = [:positive] |> System.unique_integer() |> Integer.to_string()
    Path.join(System.tmp_dir!(), "codex_app_server_schema_snapshot_#{suffix}")
  end

  defp default_output_path do
    Path.expand("../../../priv/schema", __DIR__)
  end

  defp remove_path(path) do
    case File.rm_rf(path) do
      {:ok, _paths} -> :ok
      {:error, reason, _path} -> {:error, {:remove_failed, path, reason}}
    end
  end
end
