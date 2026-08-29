defmodule CodexEx.AppServer.Protocol.GeneratorTest do
  use ExUnit.Case, async: true

  alias CodexEx.AppServer.Protocol.Generator

  test "generates protocol files from the committed schema snapshot" do
    output_path =
      Path.join(
        System.tmp_dir!(),
        "codex_protocol_generator_test_#{System.unique_integer([:positive])}"
      )

    on_exit(fn -> File.rm_rf(output_path) end)

    schema_root = Path.join(File.cwd!(), "priv/schema")

    assert {:ok, %{file_count: file_count, output_path: ^output_path}} =
             Generator.generate(schema_root: schema_root, output_path: output_path)

    generated_files = Path.wildcard(Path.join(output_path, "**/*.ex"))

    assert length(generated_files) == file_count
    assert File.exists?(Path.join([output_path, "shared", "server_request.ex"]))
    assert File.exists?(Path.join([output_path, "v1", "initialize_params.ex"]))
    assert File.exists?(Path.join([output_path, "v2", "turn_started_notification.ex"]))
  end

  test "formats generated files with module-relative refs and a trailing newline" do
    output_path =
      Path.join(
        System.tmp_dir!(),
        "codex_protocol_generator_nested_test_#{System.unique_integer([:positive])}"
      )

    on_exit(fn -> File.rm_rf(output_path) end)

    schema_root = Path.join(File.cwd!(), "priv/schema")

    assert {:ok, %{output_path: ^output_path}} =
             Generator.generate(schema_root: schema_root, output_path: output_path)

    nested_module_source =
      File.read!(Path.join([output_path, "v2", "turn_started_notification.ex"]))

    scalar_source = File.read!(Path.join([output_path, "shared", "request_id.ex"]))

    assert nested_module_source =~ "defmodule ByteRange do"
    assert nested_module_source =~ "Codec.decode_object(__MODULE__, @field_specs, payload)"

    assert String.ends_with?(nested_module_source, "\n")
    assert String.ends_with?(scalar_source, "\n")
  end
end
