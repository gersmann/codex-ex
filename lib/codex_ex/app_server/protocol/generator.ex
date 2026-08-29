defmodule CodexEx.AppServer.Protocol.Generator do
  @moduledoc false

  alias Mix.Tasks.Format, as: MixFormat

  @base_namespace CodexEx.AppServer.Protocol.Generated
  @bundle_filenames MapSet.new([
                      "codex_app_server_protocol.schemas.json",
                      "codex_app_server_protocol.v2.schemas.json"
                    ])
  @envelope_titles MapSet.new([
                     "ClientNotification",
                     "ClientRequest",
                     "ServerNotification",
                     "ServerRequest"
                   ])

  @type result ::
          {:ok, %{file_count: non_neg_integer(), output_path: Path.t()}}
          | {:error, {:invalid_schema_root, Path.t()}}
          | {:error, {:schema_decode_failed, Path.t(), term()}}
          | {:error, {:schema_read_failed, Path.t(), term()}}
          | {:error, {:unknown_envelope_params_schema, binary(), binary()}}
          | {:error, {:write_failed, Path.t(), term()}}
  @dialyzer {:nowarn_function, [generate: 1]}

  @spec generate(keyword()) :: {:ok, term()} | {:error, term()}
  def generate(opts \\ []) do
    schema_root = opts |> Keyword.get(:schema_root, default_schema_root()) |> Path.expand()
    output_path = opts |> Keyword.get(:output_path, default_output_path()) |> Path.expand()

    with :ok <- validate_schema_root(schema_root),
         {:ok, schema_files} <- load_schema_files(schema_root),
         :ok <- recreate_output_path(output_path),
         {:ok, file_count} <- write_generated_files(schema_files, output_path),
         :ok <- format_output_path(output_path) do
      {:ok, %{file_count: file_count, output_path: output_path}}
    end
  end

  defp validate_schema_root(schema_root) do
    if File.dir?(schema_root) do
      :ok
    else
      {:error, {:invalid_schema_root, schema_root}}
    end
  end

  defp load_schema_files(schema_root) do
    schema_root
    |> Path.join("**/*.json")
    |> Path.wildcard(match_dot: true)
    |> Enum.reject(&(Path.basename(&1) in @bundle_filenames))
    |> Enum.sort()
    |> Enum.reduce_while({:ok, []}, fn path, {:ok, acc} ->
      relative_path = Path.relative_to(path, schema_root)
      basename = Path.basename(path, ".json")

      with {:ok, contents} <- File.read(path),
           {:ok, schema} <- Jason.decode(contents) do
        title = Map.get(schema, "title", basename)

        schema_file = %{
          basename: basename,
          path: path,
          relative_path: relative_path,
          schema: schema,
          title: title
        }

        {:cont, {:ok, [schema_file | acc]}}
      else
        {:error, %Jason.DecodeError{} = reason} ->
          {:halt, {:error, {:schema_decode_failed, path, reason}}}

        {:error, reason} ->
          {:halt, {:error, {:schema_read_failed, path, reason}}}
      end
    end)
    |> case do
      {:ok, schema_files} -> {:ok, Enum.reverse(schema_files)}
      error -> error
    end
  rescue
    error in File.Error ->
      {:error, {:schema_read_failed, error.path, error.reason}}
  end

  defp recreate_output_path(output_path) do
    case File.rm_rf(output_path) do
      {:ok, _paths} -> File.mkdir_p(output_path)
      {:error, reason, _path} -> {:error, {:write_failed, output_path, reason}}
    end
  end

  defp write_generated_files(schema_files, output_path) do
    module_index =
      Map.new(schema_files, fn schema_file ->
        {schema_file.title, module_info_for(schema_file.relative_path, schema_file.basename)}
      end)

    Enum.reduce_while(schema_files, {:ok, 0}, fn schema_file, {:ok, count} ->
      module_info = module_info_for(schema_file.relative_path, schema_file.basename)
      output_file = module_info.output_path.(output_path)

      with {:ok, source} <- build_source(schema_file, module_info, module_index),
           :ok <- File.mkdir_p(Path.dirname(output_file)),
           :ok <- File.write(output_file, source) do
        {:cont, {:ok, count + 1}}
      else
        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
  end

  defp build_source(%{schema: %{"title" => title} = schema}, module_info, module_index) do
    source =
      if MapSet.member?(@envelope_titles, title) do
        build_envelope_source(schema, module_info.module, module_index)
      else
        build_schema_module_source(schema, module_info.module)
      end

    {:ok, format_source(source)}
  rescue
    error in RuntimeError ->
      {:error, {:write_failed, module_info.relative_path, Exception.message(error)}}
  end

  defp build_schema_module_source(schema, module) do
    if object_schema?(schema) do
      definitions = Map.get(schema, "definitions", %{})
      nested_definitions = object_definitions(module, definitions)

      nested_definition_modules =
        Map.new(nested_definitions, fn {name, nested_module, _schema} -> {name, nested_module} end)

      body = render_object_module_body(module, schema, nested_definition_modules)

      nested_sources =
        nested_definitions
        |> Enum.sort_by(fn {name, _module, _schema} -> name end)
        |> Enum.map_join("\n\n", fn {name, nested_module, nested_schema} ->
          """
            defmodule #{name} do
              @moduledoc false

              alias CodexEx.AppServer.Protocol.Codec

          #{indent(render_object_module_body(nested_module, nested_schema, nested_definition_modules), 6)}
            end
          """
        end)

      """
      defmodule #{inspect(module)} do
        @moduledoc false

        alias CodexEx.AppServer.Protocol.Codec

      #{indent(body, 4)}

      #{nested_sources}
      end
      """
    else
      """
      defmodule #{inspect(module)} do
        @moduledoc false

        alias CodexEx.AppServer.Protocol.Codec

        def decode(value), do: value
        def encode(value), do: Codec.encode_value(:plain, value)
      end
      """
    end
  end

  defp build_envelope_source(schema, module, module_index) do
    method_specs =
      schema
      |> Map.get("oneOf", [])
      |> Enum.map(&envelope_variant_spec(&1, module_index))
      |> Enum.sort_by(fn {method, _spec} -> method end)

    params_helpers = envelope_params_helpers(method_specs)

    """
    defmodule #{inspect(module)} do
      @moduledoc false

      alias CodexEx.AppServer.Protocol.Codec

      defstruct [:id, :method, :params]

      @method_specs #{render_method_specs(method_specs)}

      def methods, do: Map.keys(@method_specs)
      def known_method?(method) when is_binary(method), do: Map.has_key?(@method_specs, method)

      def decode(%{"method" => method} = payload) when is_binary(method) do
        spec = Map.get(@method_specs, method, %{})
        params_module = Map.get(spec, :params_module)
        params = Map.get(payload, "params")

        %__MODULE__{
          id: Map.get(payload, "id"),
          method: method,
          params: decode_params(params_module, params)
        }
      end

      def decode(other), do: other

      def encode(%__MODULE__{} = message) do
        spec = Map.get(@method_specs, message.method, %{})

        %{"method" => message.method}
        |> maybe_put_id(message.id)
        |> maybe_put_params(Map.get(spec, :params_module), message.params)
      end

      def encode(other), do: Codec.encode_value(:plain, other)

    #{indent(params_helpers, 2)}

      defp maybe_put_id(payload, nil), do: payload
      defp maybe_put_id(payload, id), do: Map.put(payload, "id", id)
    end
    """
  end

  # Renders the map literal from method-sorted entries; inspecting a map directly
  # would follow internal hash order, which varies across OTP releases.
  defp render_method_specs(method_specs) do
    entries =
      Enum.map_join(method_specs, ",\n", fn {method, spec} ->
        "#{inspect(method)} => #{inspect(spec, limit: :infinity)}"
      end)

    "%{\n#{entries}\n}"
  end

  defp envelope_params_helpers(method_specs) do
    if Enum.any?(method_specs, fn {_method, spec} -> Map.get(spec, :params_module) end) do
      """
      defp decode_params(nil, nil), do: nil
      defp decode_params(nil, params), do: params
      defp decode_params(module, nil), do: module.decode(%{})
      defp decode_params(module, params), do: module.decode(params)

      defp maybe_put_params(payload, nil, nil), do: payload
      defp maybe_put_params(payload, nil, %{} = params) when map_size(params) == 0, do: payload
      defp maybe_put_params(payload, nil, params), do: Map.put(payload, "params", params)

      defp maybe_put_params(payload, module, params) do
        Map.put(payload, "params", module.encode(params))
      end
      """
    else
      """
      defp decode_params(nil, nil), do: nil
      defp decode_params(nil, params), do: params

      defp maybe_put_params(payload, nil, nil), do: payload
      defp maybe_put_params(payload, nil, %{} = params) when map_size(params) == 0, do: payload
      defp maybe_put_params(payload, nil, params), do: Map.put(payload, "params", params)
      """
    end
  end

  defp envelope_variant_spec(variant, module_index) do
    method =
      variant
      |> get_in(["properties", "method", "enum"])
      |> List.first()

    params_module =
      case get_in(variant, ["properties", "params", "$ref"]) do
        nil ->
          nil

        "#/definitions/" <> definition_name ->
          case Map.fetch(module_index, definition_name) do
            {:ok, %{module: module}} ->
              module

            :error ->
              raise "unknown params schema #{definition_name} for method #{method}"
          end
      end

    {method, %{params_module: params_module}}
  end

  defp render_object_module_body(module, schema, object_definitions) do
    field_specs =
      schema
      |> collect_object_property_schemas()
      |> Enum.sort_by(fn {wire_key, _property} -> wire_key end)
      |> Enum.map(fn {wire_key, property_schema} ->
        %{
          field: wire_key_to_field(wire_key),
          required: field_required?(schema, wire_key),
          spec: build_value_spec(property_schema, object_definitions),
          wire_key: wire_key
        }
      end)

    fields = Enum.map(field_specs, & &1.field)

    [
      render_parent_module_alias(module, field_specs),
      "defstruct #{inspect(fields)}",
      "@field_specs #{render_field_specs_source(field_specs, module)}",
      """
      def decode(payload) when is_map(payload) do
        Codec.decode_object(__MODULE__, @field_specs, payload)
      end
      """,
      "def decode(other), do: other",
      "def encode(%__MODULE__{} = value), do: Codec.encode_object(value, @field_specs)",
      "def encode(other), do: Codec.encode_value(:plain, other)"
    ]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n\n")
  end

  defp collect_object_property_schemas(schema) when is_map(schema) do
    schema
    |> property_schema_sources()
    |> Enum.reduce(%{}, fn property_map, acc ->
      Map.merge(acc, property_map, fn _wire_key, left_schema, right_schema ->
        merge_property_schemas(left_schema, right_schema)
      end)
    end)
  end

  defp collect_object_property_schemas(_schema), do: %{}

  defp property_schema_sources(schema) when is_map(schema) do
    base_properties =
      case Map.get(schema, "properties") do
        properties when is_map(properties) -> [properties]
        _other -> []
      end

    variant_properties =
      schema
      |> Map.get("oneOf", [])
      |> Enum.flat_map(fn
        %{"properties" => properties} when is_map(properties) -> [properties]
        _variant -> []
      end)

    base_properties ++ variant_properties
  end

  defp field_required?(schema, wire_key) when is_map(schema) and is_binary(wire_key) do
    wire_key in Map.get(schema, "required", [])
  end

  defp field_required?(_schema, _wire_key), do: false

  defp merge_property_schemas(left_schema, right_schema) when left_schema == right_schema, do: left_schema

  defp merge_property_schemas(%{"oneOf" => schemas}, right_schema) when is_list(schemas) do
    %{"oneOf" => Enum.uniq(schemas ++ [right_schema])}
  end

  defp merge_property_schemas(left_schema, %{"oneOf" => schemas}) when is_list(schemas) do
    %{"oneOf" => Enum.uniq([left_schema | schemas])}
  end

  defp merge_property_schemas(left_schema, right_schema) do
    %{"oneOf" => Enum.uniq([left_schema, right_schema])}
  end

  defp build_value_spec(%{"$ref" => "#/definitions/" <> definition_name}, object_definitions) do
    case Map.fetch(object_definitions, definition_name) do
      {:ok, nested_module} -> {:module, nested_module}
      :error -> :plain
    end
  end

  defp build_value_spec(%{"allOf" => [schema]}, object_definitions) do
    build_value_spec(schema, object_definitions)
  end

  defp build_value_spec(%{"anyOf" => schemas}, object_definitions) when is_list(schemas) do
    build_nullable_or_plain(schemas, object_definitions)
  end

  defp build_value_spec(%{"oneOf" => schemas}, object_definitions) when is_list(schemas) do
    build_nullable_or_plain(schemas, object_definitions)
  end

  defp build_value_spec(%{"items" => item_schema, "type" => "array"}, object_definitions) do
    {:array, build_value_spec(item_schema, object_definitions)}
  end

  defp build_value_spec(%{"items" => item_schema, "type" => ["array", "null"]}, object_definitions) do
    {:nullable, {:array, build_value_spec(item_schema, object_definitions)}}
  end

  defp build_value_spec(%{"type" => types} = schema, object_definitions) when is_list(types) do
    case Enum.reject(types, &(&1 == "null")) do
      [type] ->
        build_non_null_type_spec(type, schema, object_definitions, nullable?: "null" in types)

      _other ->
        :plain
    end
  end

  defp build_value_spec(%{"type" => type} = schema, object_definitions) when is_binary(type) do
    build_non_null_type_spec(type, schema, object_definitions, nullable?: false)
  end

  defp build_value_spec(_schema, _object_definitions), do: :plain

  defp build_nullable_or_plain(schemas, object_definitions) do
    non_null_schemas =
      Enum.reject(schemas, fn
        %{"type" => "null"} -> true
        _schema -> false
      end)

    if length(non_null_schemas) == 1 and length(non_null_schemas) != length(schemas) do
      {:nullable, build_value_spec(hd(non_null_schemas), object_definitions)}
    else
      :plain
    end
  end

  defp build_non_null_type_spec("array", %{"items" => item_schema}, object_definitions, nullable?: true) do
    {:nullable, {:array, build_value_spec(item_schema, object_definitions)}}
  end

  defp build_non_null_type_spec("array", %{"items" => item_schema}, object_definitions, nullable?: false) do
    {:array, build_value_spec(item_schema, object_definitions)}
  end

  defp build_non_null_type_spec("object", _schema, _object_definitions, nullable?: true) do
    {:nullable, :plain}
  end

  defp build_non_null_type_spec("object", _schema, _object_definitions, nullable?: false), do: :plain

  defp build_non_null_type_spec(_type, _schema, _object_definitions, nullable?: true), do: {:nullable, :plain}

  defp build_non_null_type_spec(_type, _schema, _object_definitions, nullable?: false), do: :plain

  defp object_definitions(module, definitions) do
    definitions
    |> Enum.filter(fn {_name, schema} -> object_schema?(schema) end)
    |> Enum.map(fn {name, schema} -> {name, Module.concat(module, name), schema} end)
  end

  defp object_schema?(%{"type" => "object"}), do: true

  defp object_schema?(%{"type" => types}) when is_list(types) do
    Enum.member?(types, "object")
  end

  defp object_schema?(_schema), do: false

  defp wire_key_to_field(wire_key) do
    wire_key
    |> Macro.underscore()
    |> String.to_atom()
  end

  defp modules_in_value_spec(:plain), do: []
  defp modules_in_value_spec({:array, spec}), do: modules_in_value_spec(spec)
  defp modules_in_value_spec({:module, module}), do: [module]
  defp modules_in_value_spec({:nullable, spec}), do: modules_in_value_spec(spec)

  defp render_parent_module_alias(module, field_specs) do
    parent_module = parent_module(module)

    if parent_module == module or
         not references_parent_module?(field_specs, module, parent_module) do
      ""
    else
      "alias #{inspect(parent_module)}, as: ParentModule"
    end
  end

  defp references_parent_module?(field_specs, current_module, parent_module) do
    parent_parts = Module.split(parent_module)
    current_parts = Module.split(current_module)

    Enum.any?(field_specs, fn field_spec ->
      field_spec.spec
      |> modules_in_value_spec()
      |> Enum.any?(fn module ->
        module_parts = Module.split(module)

        shared_module_prefix?(module_parts, parent_parts) and
          not shared_module_prefix?(module_parts, current_parts) and module != parent_module
      end)
    end)
  end

  defp render_field_specs_source(field_specs, current_module) do
    field_specs
    |> Enum.map(&field_spec_ast(&1, current_module))
    |> then(&{:__block__, [], [&1]})
    |> Macro.to_string()
    |> String.trim_leading("[")
    |> String.trim_trailing("]")
    |> then(&"[#{&1}]")
  end

  defp field_spec_ast(field_spec, current_module) do
    quote do
      %{
        spec: unquote(value_spec_ast(field_spec.spec, current_module)),
        field: unquote(field_spec.field),
        required: unquote(field_spec.required),
        wire_key: unquote(field_spec.wire_key)
      }
    end
  end

  defp value_spec_ast(:plain, _current_module), do: quote(do: :plain)

  defp value_spec_ast({:array, spec}, current_module) do
    quote do
      {:array, unquote(value_spec_ast(spec, current_module))}
    end
  end

  defp value_spec_ast({:module, module}, current_module) do
    quote do
      {:module, unquote(module_reference_ast(module, current_module))}
    end
  end

  defp value_spec_ast({:nullable, spec}, current_module) do
    quote do
      {:nullable, unquote(value_spec_ast(spec, current_module))}
    end
  end

  defp module_reference_ast(module, current_module) do
    current_parts = Module.split(current_module)
    parent_module = parent_module(current_module)
    parent_parts = Module.split(parent_module)
    module_parts = Module.split(module)

    cond do
      shared_module_prefix?(module_parts, current_parts) ->
        remainder = module_parts |> Enum.drop(length(current_parts)) |> Enum.join(".")
        quote do: Module.concat(__MODULE__, unquote(remainder))

      parent_module != current_module and shared_module_prefix?(module_parts, parent_parts) ->
        remainder = module_parts |> Enum.drop(length(parent_parts)) |> Enum.join(".")
        quote do: Module.concat(ParentModule, unquote(remainder))

      true ->
        module
    end
  end

  defp parent_module(module) do
    module
    |> Module.split()
    |> Enum.drop(-1)
    |> Module.concat()
  end

  defp shared_module_prefix?(parts, prefix) do
    Enum.take(parts, length(prefix)) == prefix
  end

  defp module_info_for(relative_path, basename) do
    directory = Path.dirname(relative_path)

    namespace_parts =
      case directory do
        "." -> ["Shared"]
        other -> Enum.map(Path.split(other), &Macro.camelize/1)
      end

    output_dir_parts =
      case directory do
        "." -> ["shared"]
        other -> Path.split(other)
      end

    module = Module.concat([@base_namespace | namespace_parts] ++ [basename])
    output_filename = "#{Macro.underscore(basename)}.ex"

    %{
      module: module,
      relative_path: relative_path,
      output_path: fn root -> Path.join([root | output_dir_parts] ++ [output_filename]) end
    }
  end

  # The package source root — generator output and schema snapshots live in
  # the source tree, not in _build, so resolve relative to this file.
  @package_root Path.expand("../../../..", __DIR__)

  defp default_schema_root do
    Path.join(@package_root, "priv/schema")
  end

  defp default_output_path do
    Path.join(@package_root, "lib/codex_ex/app_server/protocol/generated")
  end

  defp indent(text, count) do
    padding = String.duplicate(" ", count)

    text
    |> String.trim()
    |> String.split("\n")
    |> Enum.map_join("\n", &(padding <> &1))
  end

  defp format_source(source) do
    source
    |> Code.format_string!()
    |> IO.iodata_to_binary()
    |> String.trim_trailing("\n")
    |> Kernel.<>("\n")
  end

  defp format_output_path(output_path) do
    files = Path.wildcard(Path.join(output_path, "**/*.ex"), match_dot: true)

    case files do
      [] ->
        :ok

      _files ->
        formatter_path = Path.join(@package_root, ".formatter.exs")
        MixFormat.run(["--dot-formatter", formatter_path | files])
        :ok
    end
  rescue
    error ->
      {:error, {:write_failed, output_path, Exception.message(error)}}
  end
end
