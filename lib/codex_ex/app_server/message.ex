defmodule CodexEx.AppServer.Message do
  @moduledoc """
  Helpers for protocol-native app-server notifications and server requests.
  """

  alias CodexEx.AppServer.Protocol.Generated.Shared.ApplyPatchApprovalResponse
  alias CodexEx.AppServer.Protocol.Generated.Shared.CommandExecutionRequestApprovalResponse
  alias CodexEx.AppServer.Protocol.Generated.Shared.DynamicToolCallResponse
  alias CodexEx.AppServer.Protocol.Generated.Shared.ExecCommandApprovalResponse
  alias CodexEx.AppServer.Protocol.Generated.Shared.FileChangeRequestApprovalResponse
  alias CodexEx.AppServer.Protocol.Generated.Shared.McpServerElicitationRequestResponse
  alias CodexEx.AppServer.Protocol.Generated.Shared.PermissionsRequestApprovalResponse
  alias CodexEx.AppServer.Protocol.Generated.Shared.ServerNotification
  alias CodexEx.AppServer.Protocol.Generated.Shared.ServerRequest
  alias CodexEx.AppServer.Protocol.Generated.Shared.ToolRequestUserInputResponse

  alias CodexEx.AppServer.Protocol.Generated.Shared.ToolRequestUserInputResponse.ToolRequestUserInputAnswer

  alias CodexEx.AppServer.Protocol.Generated.V2.HookCompletedNotification.HookRunSummary,
    as: CompletedHookRunSummary

  alias CodexEx.AppServer.Protocol.Generated.V2.HookStartedNotification.HookRunSummary,
    as: StartedHookRunSummary

  alias CodexEx.AppServer.Protocol.GenericNotification
  alias CodexEx.AppServer.Protocol.GenericServerRequest
  alias CodexEx.AppServer.Protocol.UnmatchedResponse
  alias CodexEx.AppServer.ProtocolValue
  alias CodexEx.AppServer.ThreadGoal
  alias CodexEx.AppServer.ThreadItem
  alias CodexEx.AppServer.TokenUsage
  alias CodexEx.AppServer.Turn

  @type t ::
          %ServerNotification{}
          | %ServerRequest{}
          | %GenericNotification{}
          | %GenericServerRequest{}
          | %UnmatchedResponse{}
  @type supported_reply_payload ::
          %ToolRequestUserInputResponse{}
          | %McpServerElicitationRequestResponse{}
          | %CommandExecutionRequestApprovalResponse{}
          | %DynamicToolCallResponse{}
          | %ExecCommandApprovalResponse{}
          | %FileChangeRequestApprovalResponse{}
          | %ApplyPatchApprovalResponse{}
          | %PermissionsRequestApprovalResponse{}
  @type hook_run_result :: {:ok, map()} | {:error, term()}
  @dialyzer {:nowarn_function,
             [resolved_request_id: 1, extract_text_delta: 1, extract_turn_diff: 1]}

  @spec method_name(term()) :: binary() | nil
  def method_name(%ServerNotification{method: method}), do: method
  def method_name(%ServerRequest{method: method}), do: method
  def method_name(%GenericNotification{method: method}), do: method
  def method_name(%GenericServerRequest{method: method}), do: method
  def method_name(%UnmatchedResponse{}), do: nil

  @spec request_id(term()) :: term() | nil
  def request_id(%ServerRequest{id: id}), do: id
  def request_id(%GenericServerRequest{id: id}), do: id
  def request_id(%UnmatchedResponse{id: id}), do: id
  def request_id(_message), do: nil

  @spec supported_reply_payload?(term()) :: boolean()
  def supported_reply_payload?(payload) do
    match?({:ok, _encoded}, encode_reply_payload(payload))
  end

  @spec encode_reply_payload(term()) ::
          {:ok, map()} | {:error, {:unsupported_request_reply_payload, term()}}
  def encode_reply_payload(%ToolRequestUserInputResponse{answers: answers} = payload)
      when is_map(answers) do
    if Enum.all?(answers, fn {_id, answer} ->
         match?(%ToolRequestUserInputAnswer{}, answer)
       end) do
      encoded_answers =
        Map.new(answers, fn {id, %ToolRequestUserInputAnswer{} = answer} ->
          {id, ToolRequestUserInputAnswer.encode(answer)}
        end)

      encoded_reply(ToolRequestUserInputResponse.encode(%{payload | answers: encoded_answers}))
    else
      {:error, {:unsupported_request_reply_payload, payload}}
    end
  end

  def encode_reply_payload(%McpServerElicitationRequestResponse{} = payload),
    do: encoded_reply(McpServerElicitationRequestResponse.encode(payload))

  def encode_reply_payload(%CommandExecutionRequestApprovalResponse{} = payload),
    do: encoded_reply(CommandExecutionRequestApprovalResponse.encode(payload))

  def encode_reply_payload(%DynamicToolCallResponse{} = payload),
    do: encoded_reply(DynamicToolCallResponse.encode(payload))

  def encode_reply_payload(%ExecCommandApprovalResponse{} = payload),
    do: encoded_reply(ExecCommandApprovalResponse.encode(payload))

  def encode_reply_payload(%FileChangeRequestApprovalResponse{} = payload),
    do: encoded_reply(FileChangeRequestApprovalResponse.encode(payload))

  def encode_reply_payload(%ApplyPatchApprovalResponse{} = payload),
    do: encoded_reply(ApplyPatchApprovalResponse.encode(payload))

  def encode_reply_payload(%PermissionsRequestApprovalResponse{} = payload),
    do: encoded_reply(PermissionsRequestApprovalResponse.encode(payload))

  def encode_reply_payload(payload), do: {:error, {:unsupported_request_reply_payload, payload}}

  defp encoded_reply(encoded), do: {:ok, Map.new(encoded)}

  @spec resolved_request_id(term()) :: term() | nil
  def resolved_request_id(message) do
    if method_name(message) == "serverRequest/resolved" do
      case ProtocolValue.fetch(params(message), :request_id) do
        {:ok, request_id} -> request_id
        :error -> nil
      end
    end
  end

  @spec thread_id(term()) :: binary() | nil
  def thread_id(message) do
    message
    |> params()
    |> do_extract_thread_id()
  end

  @spec turn_id(term()) :: binary() | nil
  def turn_id(message) do
    message
    |> params()
    |> do_extract_turn_id()
  end

  @spec item_id(term()) :: binary() | nil
  def item_id(message) do
    message
    |> params()
    |> do_extract_item_id()
  end

  @spec extract_item(term()) :: ThreadItem.result() | nil
  def extract_item(message) do
    case fetch_param(params(message), :item) do
      {:ok, item} -> ThreadItem.from_protocol(item)
      :error -> nil
    end
  end

  @spec extract_turn(term()) :: Turn.result() | nil
  def extract_turn(message) do
    thread_id = thread_id(message)

    case {fetch_param(params(message), :turn), thread_id} do
      {{:ok, turn}, thread_id} when is_binary(thread_id) ->
        Turn.from_protocol(turn, thread_id)

      {{:ok, _turn}, _thread_id} ->
        {:error, {:invalid_turn, {:missing_thread_id, method_name(message)}}}

      _other ->
        nil
    end
  end

  @spec extract_hook_run(term()) :: hook_run_result() | nil
  def extract_hook_run(message) do
    if method_name(message) in ["hook/started", "hook/completed"] do
      case fetch_param(params(message), :run) do
        {:ok, run} -> encode_hook_run(run)
        :error -> nil
      end
    end
  end

  @spec hook_run_item_attributes(map()) :: map() | nil
  def hook_run_item_attributes(%{} = hook_run) do
    case hook_run_item_key(hook_run) do
      item_key when is_binary(item_key) ->
        detail = hook_run_detail(hook_run)
        output = hook_run_output(hook_run)

        %{
          attrs: Map.merge(hook_run, %{"detail" => detail, "output" => output}),
          external_item_id: item_key,
          item_key: item_key,
          text: first_non_empty_binary([output, detail]),
          type: "hook"
        }

      nil ->
        nil
    end
  end

  def hook_run_item_attributes(_hook_run), do: nil

  @spec extract_text_delta(term()) :: binary() | nil
  def extract_text_delta(message) do
    if method_name(message) in ["item/agentMessage/delta", "item/plan/delta"] do
      case ProtocolValue.get(params(message), :delta) do
        delta when is_binary(delta) -> delta
        _other -> nil
      end
    end
  end

  @spec extract_turn_diff(term()) :: binary() | nil
  def extract_turn_diff(message) do
    if method_name(message) == "turn/diff/updated" do
      case ProtocolValue.get(params(message), :diff) do
        diff when is_binary(diff) -> diff
        _other -> nil
      end
    end
  end

  @spec extract_token_usage(t()) :: TokenUsage.result() | nil
  def extract_token_usage(message) do
    if method_name(message) == "thread/tokenUsage/updated" do
      normalize_token_usage(params(message))
    end
  end

  @spec extract_thread_goal(t()) :: ThreadGoal.result() | nil
  def extract_thread_goal(message) do
    if method_name(message) == "thread/goal/updated" do
      normalize_thread_goal(params(message))
    end
  end

  defp params(%ServerNotification{params: params}), do: params
  defp params(%ServerRequest{params: params}), do: params
  defp params(%GenericNotification{params: params}), do: params
  defp params(%GenericServerRequest{params: params}), do: params
  defp params(%UnmatchedResponse{payload: payload}), do: payload

  defp do_extract_thread_id(%{} = params) do
    cond do
      is_binary(get_value(params, :thread_id)) ->
        get_value(params, :thread_id)

      is_binary(get_value(params, :conversation_id)) ->
        get_value(params, :conversation_id)

      is_binary(nested_id(get_value(params, :thread))) ->
        nested_id(get_value(params, :thread))

      is_binary(get_value(get_value(params, :turn) || %{}, :thread_id)) ->
        get_value(get_value(params, :turn) || %{}, :thread_id)

      true ->
        nil
    end
  end

  defp do_extract_thread_id(_params), do: nil

  defp do_extract_turn_id(%{} = params) do
    cond do
      is_binary(get_value(params, :turn_id)) ->
        get_value(params, :turn_id)

      is_binary(nested_id(get_value(params, :turn))) ->
        nested_id(get_value(params, :turn))

      true ->
        nil
    end
  end

  defp do_extract_turn_id(_params), do: nil

  defp do_extract_item_id(%{} = params) do
    cond do
      is_binary(get_value(params, :item_id)) ->
        get_value(params, :item_id)

      is_binary(nested_id(get_value(params, :item))) ->
        nested_id(get_value(params, :item))

      true ->
        nil
    end
  end

  defp do_extract_item_id(_params), do: nil

  defp nested_id(nil), do: nil
  defp nested_id(%module{id: id}) when is_atom(module) and is_binary(id), do: id
  defp nested_id(%{"id" => id}) when is_binary(id), do: id
  defp nested_id(_value), do: nil

  defp get_value(map, key, default \\ nil) do
    ProtocolValue.get(map, key, default)
  end

  defp fetch_param(%{} = params, key), do: ProtocolValue.fetch(params, key)
  defp fetch_param(_params, _key), do: :error

  defp encode_hook_run(%StartedHookRunSummary{} = run),
    do: {:ok, StartedHookRunSummary.encode(run)}

  defp encode_hook_run(%CompletedHookRunSummary{} = run),
    do: {:ok, CompletedHookRunSummary.encode(run)}

  defp encode_hook_run(run) do
    case ProtocolValue.to_json_value(run) do
      {:ok, %{} = attrs} -> {:ok, attrs}
      {:ok, other} -> {:error, {:invalid_hook_run, {:invalid_attrs, other}}}
      {:error, reason} -> {:error, {:invalid_hook_run, reason}}
    end
  end

  defp hook_run_item_key(%{} = hook_run) do
    case {Map.get(hook_run, "eventName"), Map.get(hook_run, "displayOrder"),
          Map.get(hook_run, "sourcePath")} do
      {event_name, display_order, source_path}
      when is_binary(event_name) and event_name != "" and is_integer(display_order) and
             is_binary(source_path) and source_path != "" ->
        "#{event_name}:#{display_order}:#{source_path}"

      _other ->
        hook_run_id_item_key(Map.get(hook_run, "id"))
    end
  end

  defp hook_run_id_item_key(id) when is_binary(id) and id != "", do: "hook:#{id}"
  defp hook_run_id_item_key(_id), do: nil

  defp hook_run_output(%{"entries" => entries}) when is_list(entries) do
    entries
    |> Enum.map(&Map.get(&1, "text"))
    |> Enum.filter(&is_binary/1)
    |> case do
      [] -> ""
      texts -> Enum.join(texts, "\n")
    end
  end

  defp hook_run_output(_hook_run), do: ""

  defp hook_run_detail(hook_run) when is_map(hook_run) do
    first_non_empty_binary([
      Map.get(hook_run, "statusMessage"),
      Map.get(hook_run, "eventName"),
      Map.get(hook_run, "sourcePath")
    ])
  end

  defp first_non_empty_binary(values) when is_list(values) do
    Enum.find_value(values, "", fn
      value when is_binary(value) ->
        if String.trim(value) == "", do: nil, else: value

      _other ->
        nil
    end)
  end

  defp normalize_token_usage(params) do
    case fetch_param(params, :token_usage) do
      {:ok, token_usage} -> TokenUsage.from_protocol(token_usage)
      :error -> {:error, {:invalid_token_usage, {:missing_field, :token_usage}}}
    end
  end

  defp normalize_thread_goal(params) do
    case fetch_param(params, :goal) do
      {:ok, goal} -> ThreadGoal.from_protocol(goal)
      :error -> {:error, {:invalid_thread_goal, {:missing_field, :goal}}}
    end
  end
end
