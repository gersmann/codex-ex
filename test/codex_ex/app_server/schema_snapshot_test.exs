defmodule CodexEx.AppServer.SchemaSnapshotTest do
  use ExUnit.Case, async: true

  alias CodexEx.AppServer.SchemaSnapshot

  setup do
    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "schema_snapshot_test_#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp_dir)
    on_exit(fn -> File.rm_rf(tmp_dir) end)

    fixture =
      Path.join([File.cwd!(), "test", "support", "fixtures", "mock_codex_schema_export.sh"])

    {:ok, fixture: fixture, tmp_dir: tmp_dir}
  end

  test "exports the schema into the target path and removes stale files", %{
    fixture: fixture,
    tmp_dir: tmp_dir
  } do
    output_path = Path.join(tmp_dir, "snapshot")
    stale_path = Path.join(output_path, "stale.txt")

    File.mkdir_p!(output_path)
    File.write!(stale_path, "stale")

    assert {:ok, %{file_count: file_count, output_path: ^output_path}} =
             SchemaSnapshot.snapshot(executable: fixture, output_path: output_path)

    assert file_count == 2
    refute File.exists?(stale_path)
    assert File.exists?(Path.join([output_path, "v1", "InitializeParams.json"]))
    assert File.exists?(Path.join([output_path, "v2", "ThreadStartedNotification.json"]))
  end

  test "returns an error when the executable is missing", %{tmp_dir: tmp_dir} do
    output_path = Path.join(tmp_dir, "snapshot")

    assert {:error, :codex_executable_not_found} =
             SchemaSnapshot.snapshot(executable: "", output_path: output_path)
  end

  test "canonicalizes equivalent combined schemas", %{tmp_dir: tmp_dir} do
    output_path = Path.join(tmp_dir, "snapshot")

    first_fixture =
      write_schema_fixture!(
        tmp_dir,
        "first_export.sh",
        ~s({"title":"Example","definitions":{"Zulu":{"type":"string"},"Alpha":{"properties":{"z":1,"a":2}}}})
      )

    second_fixture =
      write_schema_fixture!(
        tmp_dir,
        "second_export.sh",
        ~s({"title":"Example","definitions":{"Alpha":{"properties":{"z":1,"a":2}},"Zulu":{"type":"string"}}})
      )

    assert {:ok, _result} =
             SchemaSnapshot.snapshot(executable: first_fixture, output_path: output_path)

    first_snapshot =
      File.read!(Path.join(output_path, "codex_app_server_protocol.v2.schemas.json"))

    assert {:ok, _result} =
             SchemaSnapshot.snapshot(executable: second_fixture, output_path: output_path)

    assert File.read!(Path.join(output_path, "codex_app_server_protocol.v2.schemas.json")) ==
             first_snapshot
  end

  defp write_schema_fixture!(tmp_dir, name, json) do
    path = Path.join(tmp_dir, name)

    File.write!(path, """
    #!/usr/bin/env sh
    set -eu
    mkdir -p "$5"
    cat > "$5/codex_app_server_protocol.v2.schemas.json" <<'EOF'
    #{json}
    EOF
    """)

    File.chmod!(path, 0o755)
    path
  end
end
