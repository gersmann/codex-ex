defmodule CodexEx.AppServer.Protocol.Verifier do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Generator

  @package_root Path.expand("../../../..", __DIR__)

  @type drift ::
          {:missing_file, Path.t()}
          | {:unexpected_file, Path.t()}
          | {:changed_file, Path.t()}

  @type result ::
          {:ok, %{file_count: non_neg_integer(), generated_path: Path.t()}}
          | {:error, {:drift_detected, [drift()]}}
          | Generator.result()

  @spec verify(keyword()) :: {:ok, term()} | {:error, term()}
  def verify(opts \\ []) do
    schema_root = opts |> Keyword.get(:schema_root, default_schema_root()) |> Path.expand()

    generated_path =
      opts |> Keyword.get(:generated_path, default_generated_path()) |> Path.expand()

    tmp_path = temporary_output_path()

    try do
      with {:ok, %{file_count: file_count}} <-
             Generator.generate(schema_root: schema_root, output_path: tmp_path),
           drifts = compare_directories(generated_path, tmp_path),
           :ok <- ensure_no_drift(drifts) do
        {:ok, %{file_count: file_count, generated_path: generated_path}}
      end
    after
      File.rm_rf(tmp_path)
    end
  end

  @spec compare_directories(term(), term()) :: [drift()]
  def compare_directories(left_path, right_path) do
    left_files = list_relative_files(left_path)
    right_files = list_relative_files(right_path)

    missing_files =
      right_files
      |> MapSet.difference(left_files)
      |> Enum.map(&{:missing_file, &1})

    unexpected_files =
      left_files
      |> MapSet.difference(right_files)
      |> Enum.map(&{:unexpected_file, &1})

    changed_files =
      left_files
      |> MapSet.intersection(right_files)
      |> Enum.filter(&(File.read!(Path.join(left_path, &1)) != File.read!(Path.join(right_path, &1))))
      |> Enum.map(&{:changed_file, &1})

    missing_files ++ unexpected_files ++ changed_files
  end

  defp ensure_no_drift([]), do: :ok
  defp ensure_no_drift(drifts), do: {:error, {:drift_detected, Enum.sort(drifts)}}

  defp list_relative_files(path) do
    path
    |> Path.join("**/*.ex")
    |> Path.wildcard(match_dot: true)
    |> MapSet.new(&Path.relative_to(&1, path))
  end

  defp default_schema_root do
    Path.join(@package_root, "priv/schema")
  end

  defp default_generated_path do
    Path.join(@package_root, "lib/codex_ex/app_server/protocol/generated")
  end

  defp temporary_output_path do
    suffix = [:positive] |> System.unique_integer() |> Integer.to_string()
    Path.join(System.tmp_dir!(), "codex_app_server_protocol_verify_#{suffix}")
  end
end
