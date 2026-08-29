defmodule CodexEx.AppServer.ThreadItem do
  @moduledoc """
  Typed app-level representation of thread items.

  The protocol currently surfaces several item unions as plain maps in generated
  Elixir modules. This module normalizes the known public shapes into stable
  structs and keeps a typed generic fallback for unsupported item variants.
  """

  alias CodexEx.AppServer.ProtocolValue
  alias CodexEx.AppServer.Types

  defmodule AgentMessage do
    @moduledoc """
    The one item type whose text streams in deltas, so the runtime needs it
    typed. `attrs` still carries the complete protocol payload — `phase` and
    `status` are conveniences read from it, not a replacement for it.
    """

    defstruct [:id, :phase, :status, :text, attrs: %{}, type: "agentMessage"]

    @type t :: %__MODULE__{
            id: binary(),
            phase: Types.json_value() | nil,
            status: Types.json_value() | nil,
            text: binary() | nil,
            attrs: Types.json_object(),
            type: binary()
          }
  end

  defmodule Generic do
    @moduledoc false

    defstruct [:id, :type, :attrs]

    @type t :: %__MODULE__{
            id: binary() | nil,
            type: binary(),
            attrs: Types.json_object()
          }
  end

  @type t :: AgentMessage.t() | Generic.t()
  @type result :: {:ok, t()} | {:error, {:invalid_thread_item, term()}}
  @dialyzer {:nowarn_function, [from_protocol: 1]}

  @spec from_protocol(term()) ::
          {:ok, AgentMessage.t() | Generic.t()} | {:error, {:invalid_thread_item, term()}}
  def from_protocol(%__MODULE__.AgentMessage{} = item), do: {:ok, item}
  def from_protocol(%__MODULE__.Generic{} = item), do: {:ok, item}

  def from_protocol(%module{} = item) when is_atom(module) do
    item
    |> Map.from_struct()
    |> from_protocol()
  end

  def from_protocol(%{} = item) do
    item = ProtocolValue.normalize_map(item)

    case ProtocolValue.get(item, :type) do
      "agentMessage" -> normalize_agent_message(item)
      type when is_binary(type) -> normalize_generic(item, type)
      nil -> {:error, {:invalid_thread_item, {:missing_field, :type}}}
      other -> {:error, {:invalid_thread_item, {:invalid_field, :type, other}}}
    end
  end

  def from_protocol(other), do: {:error, {:invalid_thread_item, {:unexpected_payload, other}}}

  @spec id(term()) :: binary() | nil
  def id(%AgentMessage{id: id}) when is_binary(id), do: id
  def id(%Generic{id: id}) when is_binary(id) or is_nil(id), do: id
  def id(_item), do: nil

  @spec type(term()) :: binary() | nil
  def type(%AgentMessage{type: type}) when is_binary(type), do: type
  def type(%Generic{type: type}) when is_binary(type), do: type
  def type(_item), do: nil

  @spec text(term()) :: binary() | nil
  def text(%AgentMessage{text: text}) when is_binary(text), do: text
  def text(%AgentMessage{text: nil}), do: nil
  def text(%Generic{}), do: nil
  def text(_item), do: nil

  defp normalize_agent_message(item) do
    with {:ok, id} <- fetch_required_binary(item, :id),
         {:ok, text} <- fetch_optional_binary(item, :text),
         {:ok, phase} <- fetch_optional_json(item, :phase),
         {:ok, status} <- fetch_optional_json(item, :status),
         {:ok, attrs} <- normalize_attrs(item) do
      {:ok,
       %AgentMessage{
         id: id,
         phase: phase,
         status: status,
         text: text,
         attrs: attrs
       }}
    end
  end

  defp normalize_generic(item, type) do
    with {:ok, id} <- fetch_optional_binary(item, :id),
         {:ok, attrs} <- normalize_attrs(item) do
      {:ok, %Generic{id: id, type: type, attrs: attrs}}
    end
  end

  defp fetch_required_binary(map, field) do
    case ProtocolValue.fetch(map, field) do
      {:ok, value} when is_binary(value) -> {:ok, value}
      {:ok, value} -> {:error, {:invalid_thread_item, {:invalid_field, field, value}}}
      :error -> {:error, {:invalid_thread_item, {:missing_field, field}}}
    end
  end

  defp fetch_optional_binary(map, field) do
    case ProtocolValue.fetch(map, field) do
      {:ok, value} when is_binary(value) -> {:ok, value}
      {:ok, nil} -> {:ok, nil}
      {:ok, value} -> {:error, {:invalid_thread_item, {:invalid_field, field, value}}}
      :error -> {:ok, nil}
    end
  end

  defp fetch_optional_json(map, field) do
    case ProtocolValue.fetch(map, field) do
      {:ok, value} -> wrap_json_result(ProtocolValue.to_json_value(value))
      :error -> {:ok, nil}
    end
  end

  defp normalize_attrs(item) do
    case ProtocolValue.to_json_value(item) do
      {:ok, attrs} when is_map(attrs) -> {:ok, attrs}
      {:ok, other} -> {:error, {:invalid_thread_item, {:invalid_attrs, other}}}
      {:error, reason} -> {:error, {:invalid_thread_item, reason}}
    end
  end

  defp wrap_json_result({:ok, value}), do: {:ok, value}
  defp wrap_json_result({:error, reason}), do: {:error, {:invalid_thread_item, reason}}
end
