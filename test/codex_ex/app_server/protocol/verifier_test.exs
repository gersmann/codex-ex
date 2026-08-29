defmodule CodexEx.AppServer.Protocol.VerifierTest do
  use ExUnit.Case, async: true

  alias CodexEx.AppServer.Protocol.Verifier

  test "verifies the committed generated protocol tree is up to date" do
    schema_root = Path.join(File.cwd!(), "priv/schema")
    generated_path = Path.join(File.cwd!(), "lib/codex_ex/app_server/protocol/generated")

    assert {:ok, %{file_count: file_count, generated_path: ^generated_path}} =
             Verifier.verify(schema_root: schema_root, generated_path: generated_path)

    assert file_count > 0
  end

  test "reports changed files as drift" do
    left_path =
      Path.join(
        System.tmp_dir!(),
        "codex_protocol_verifier_left_#{System.unique_integer([:positive])}"
      )

    right_path =
      Path.join(
        System.tmp_dir!(),
        "codex_protocol_verifier_right_#{System.unique_integer([:positive])}"
      )

    on_exit(fn ->
      File.rm_rf(left_path)
      File.rm_rf(right_path)
    end)

    File.mkdir_p!(left_path)
    File.mkdir_p!(right_path)

    File.write!(Path.join(left_path, "sample.ex"), "left\n")
    File.write!(Path.join(right_path, "sample.ex"), "right\n")
    File.write!(Path.join(right_path, "missing.ex"), "missing\n")
    File.write!(Path.join(left_path, "unexpected.ex"), "unexpected\n")

    assert [
             {:changed_file, "sample.ex"},
             {:missing_file, "missing.ex"},
             {:unexpected_file, "unexpected.ex"}
           ] = Enum.sort(Verifier.compare_directories(left_path, right_path))
  end
end
