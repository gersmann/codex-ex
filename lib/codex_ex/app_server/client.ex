defmodule CodexEx.AppServer.Client do
  @moduledoc """
  Public entrypoint for the Codex app-server client.

  This module owns the long-lived session process, exposes the thread and turn
  request helpers, broadcasts parsed server events to subscribers, and can
  auto-reply to server-initiated requests through `register_request_handler/2`.
  """

  use GenServer

  alias CodexEx.AppServer.Message
  alias CodexEx.AppServer.Protocol.Generated.Shared.FuzzyFileSearchSessionStartParams
  alias CodexEx.AppServer.Protocol.Generated.Shared.FuzzyFileSearchSessionStartResponse
  alias CodexEx.AppServer.Protocol.Generated.Shared.FuzzyFileSearchSessionStopParams
  alias CodexEx.AppServer.Protocol.Generated.Shared.FuzzyFileSearchSessionStopResponse
  alias CodexEx.AppServer.Protocol.Generated.Shared.FuzzyFileSearchSessionUpdateParams
  alias CodexEx.AppServer.Protocol.Generated.Shared.FuzzyFileSearchSessionUpdateResponse
  alias CodexEx.AppServer.Protocol.Generated.Shared.ServerNotification
  alias CodexEx.AppServer.Protocol.Generated.V1.InitializeParams
  alias CodexEx.AppServer.Protocol.Generated.V1.InitializeResponse
  alias CodexEx.AppServer.Protocol.Generated.V2.ConfigBatchWriteParams
  alias CodexEx.AppServer.Protocol.Generated.V2.ConfigBatchWriteParams.ConfigEdit
  alias CodexEx.AppServer.Protocol.Generated.V2.ConfigReadParams
  alias CodexEx.AppServer.Protocol.Generated.V2.ConfigReadResponse
  alias CodexEx.AppServer.Protocol.Generated.V2.ConfigWriteResponse
  alias CodexEx.AppServer.Protocol.Generated.V2.ExperimentalFeatureEnablementSetParams
  alias CodexEx.AppServer.Protocol.Generated.V2.ExperimentalFeatureEnablementSetResponse
  alias CodexEx.AppServer.Protocol.Generated.V2.ExperimentalFeatureListParams
  alias CodexEx.AppServer.Protocol.Generated.V2.ExperimentalFeatureListResponse
  alias CodexEx.AppServer.Protocol.Generated.V2.HooksListParams
  alias CodexEx.AppServer.Protocol.Generated.V2.HooksListResponse
  alias CodexEx.AppServer.Protocol.Generated.V2.McpResourceReadParams
  alias CodexEx.AppServer.Protocol.Generated.V2.McpResourceReadResponse
  alias CodexEx.AppServer.Protocol.Generated.V2.McpServerToolCallParams
  alias CodexEx.AppServer.Protocol.Generated.V2.McpServerToolCallResponse
  alias CodexEx.AppServer.Protocol.Generated.V2.ModelListParams
  alias CodexEx.AppServer.Protocol.Generated.V2.ModelListResponse
  alias CodexEx.AppServer.Protocol.Generated.V2.ReviewStartParams
  alias CodexEx.AppServer.Protocol.Generated.V2.SkillsListParams
  alias CodexEx.AppServer.Protocol.Generated.V2.SkillsListResponse
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadArchiveParams
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadCompactStartParams
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadForkParams
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadGoalClearParams
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadGoalGetParams
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadGoalGetResponse
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadGoalSetParams
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadGoalSetResponse
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadInjectItemsParams
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadInjectItemsResponse
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadListParams
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadListResponse
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadReadParams
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadRealtimeStartParams
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadRealtimeStopParams
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadResumeParams
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadRevertParams
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadRollbackParams
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadSetNameParams
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadStartedNotification
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadStartParams
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadStatusChangedNotification
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadTurnsListParams
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadTurnsListResponse
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadUnarchiveParams
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadUnsubscribeParams
  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadUnsubscribeResponse
  alias CodexEx.AppServer.Protocol.Generated.V2.TurnInterruptParams
  alias CodexEx.AppServer.Protocol.Generated.V2.TurnInterruptResponse
  alias CodexEx.AppServer.Protocol.Generated.V2.TurnStartParams
  alias CodexEx.AppServer.Protocol.Generated.V2.TurnSteerParams
  alias CodexEx.AppServer.Protocol.Generated.V2.TurnSteerResponse
  alias CodexEx.AppServer.Protocol.Parser
  alias CodexEx.AppServer.Protocol.UnmatchedResponse
  alias CodexEx.AppServer.ProtocolValue
  alias CodexEx.AppServer.Session
  alias CodexEx.AppServer.Thread
  alias CodexEx.AppServer.ThreadGoal
  alias CodexEx.AppServer.ThreadSettings
  alias CodexEx.AppServer.ThreadSnapshot
  alias CodexEx.AppServer.Turn
  alias CodexEx.AppServer.TurnStream
  alias CodexEx.MapHelpers

  @default_timeout 15_000
  @thread_history_timeout 60_000
  @turn_timeout 30 * 60 * 1_000
  @client_call_grace_ms 1_000
  @thread_turns_page_size 10
  @thread_activity_page_size 100
  @default_client_info %{"name" => "app", "version" => "0.1.0"}
  @realtime_feature "features.realtime_conversation"
  @thread_activity_topic "codex:thread_activity"
  @thread_start_mock_keys [
    "mockStartThreadError",
    "mockReadError",
    "mockThreadName",
    "mockThreadPreview",
    "mockThreadUpdatedAt"
  ]
  @thread_resume_mock_keys [
    "mockNoRollout",
    "mockThreadNotFound",
    "mockThreadNotLoaded",
    "mockThreadNotLoadedOnRead"
  ]
  @turn_start_mock_keys [
    "mockDelayMs",
    "mockServerRequest",
    "mockElicitationRequest",
    "mockToolApprovalElicitationRequest",
    "mockCommandExecutionApprovalRequest",
    "mockPlanItem",
    "mockMalformedTurnResult",
    "mockOmitTurnThreadId",
    "mockImmediateTurnError",
    "mockPartialTurnNotifications"
  ]
  @simple_requests %{
    config_batch_write: {"config/batchWrite", ConfigWriteResponse},
    experimental_feature_enablement_set: {"experimentalFeature/enablement/set", ExperimentalFeatureEnablementSetResponse},
    experimental_feature_list: {"experimentalFeature/list", ExperimentalFeatureListResponse},
    fuzzy_file_search_session_start: {"fuzzyFileSearch/sessionStart", FuzzyFileSearchSessionStartResponse},
    fuzzy_file_search_session_stop: {"fuzzyFileSearch/sessionStop", FuzzyFileSearchSessionStopResponse},
    fuzzy_file_search_session_update: {"fuzzyFileSearch/sessionUpdate", FuzzyFileSearchSessionUpdateResponse},
    hooks_list: {"hooks/list", HooksListResponse},
    mcp_resource_read: {"mcpServer/resource/read", McpResourceReadResponse},
    mcp_server_tool_call: {"mcpServer/tool/call", McpServerToolCallResponse},
    skills_list: {"skills/list", SkillsListResponse},
    thread_archive: {"thread/archive", :discard_response},
    thread_compact_start: {"thread/compact/start", :discard_response},
    thread_goal_clear: {"thread/goal/clear", :discard_response},
    thread_goal_get: {"thread/goal/get", ThreadGoalGetResponse},
    thread_goal_set: {"thread/goal/set", ThreadGoalSetResponse},
    thread_list: {"thread/list", ThreadListResponse},
    thread_name_set: {"thread/name/set", :discard_response},
    thread_realtime_start: {"thread/realtime/start", :discard_response},
    thread_realtime_stop: {"thread/realtime/stop", :discard_response}
  }

  @type registered_name ::
          atom()
          | {atom(), node()}
          | {:global, term()}
          | {:via, atom(), term()}
  @type t :: pid() | registered_name()
  @type request_timeout :: timeout()
  @type request_handler_reply ::
          Message.supported_reply_payload()
          | {:ok, Message.supported_reply_payload()}
          | {:error, term()}
  @type request_handler :: (term() -> request_handler_reply())
  @type request_result :: {:ok, Message.supported_reply_payload()} | {:error, term()}
  @type client_call_error :: {:client_call_failed, term()} | {:defer_failed, term()}
  @type initialize_response :: %InitializeResponse{}
  @type experimental_feature_enablement_set_response ::
          %ExperimentalFeatureEnablementSetResponse{}
  @type experimental_feature_list_response :: %ExperimentalFeatureListResponse{}
  @type config_write_response :: %ConfigWriteResponse{}
  @type config_read_response :: %ConfigReadResponse{}
  @type hooks_list_response :: %HooksListResponse{}
  @type model_list_response :: %ModelListResponse{}
  @type mcp_resource_read_response :: %McpResourceReadResponse{}
  @type mcp_server_tool_call_response :: %McpServerToolCallResponse{}
  @type skills_list_response :: %SkillsListResponse{}
  @type thread_response :: %Thread{}
  @type thread_list_response :: %{data: [ThreadSnapshot.t()], next_cursor: term()}
  @type thread_turns_page :: %{turns: [Turn.t()], next_cursor: binary() | nil}
  @type subscriber :: %{
          required(:monitor_ref) => reference(),
          required(:thread_id) => binary() | nil | :all,
          required(:reconciles_replay_gap?) => boolean()
        }
  @type subscriber_map :: %{optional(pid()) => subscriber()}
  @type pending_request_map :: %{optional(term()) => Message.t()}
  @type pending_model_list_request :: %{
          required(:ref) => reference(),
          required(:callers) => [GenServer.from()]
        }
  @type turn_interrupt_response :: %TurnInterruptResponse{}
  @type state :: %{
          initialize_result: initialize_response(),
          model_list_cache: model_list_response() | nil,
          model_list_pending: pending_model_list_request() | nil,
          pending_requests: pending_request_map(),
          replay_gap: map() | nil,
          replay_gap_owners: MapSet.t(pid()),
          broadcasts_thread_activity?: boolean(),
          thread_activity_runner_id: binary() | nil,
          thread_activity_workspace_id: binary() | nil,
          request_handler: request_handler() | nil,
          session: Session.t(),
          strict_protocol: boolean(),
          subscribers: subscriber_map()
        }
  # The generated protocol modules and deferred GenServer reply path make these
  # exported wrappers appear less precise to Dialyzer than the normalized API.
  @dialyzer {:nowarn_function,
             [
               initialize_result: 1,
               build_initialize_params: 1,
               reply_request: 4,
               list_experimental_features: 2,
               set_experimental_feature_enablement: 2,
               list_hooks: 2,
               trust_hook: 4,
               set_hook_enabled: 4,
               list_models: 1,
               list_skills: 2,
               read_mcp_resource: 4,
               call_mcp_tool: 5,
               list_threads: 2,
               start_fuzzy_file_search_session: 3,
               update_fuzzy_file_search_session: 3,
               stop_fuzzy_file_search_session: 2,
               start_thread: 2,
               start_thread_compaction: 2,
               rollback_thread: 3,
               start_review: 4,
               start_review: 5,
               resume_thread: 3,
               read_thread: 3,
               list_thread_turns: 3,
               fork_thread: 3,
               inject_thread_items: 3,
               unsubscribe_thread: 2,
               unarchive_thread: 2,
               start_realtime: 3,
               stop_realtime: 2,
               start_turn: 4,
               run: 4,
               run: 5,
               steer_turn: 5,
               steer_turn: 6,
               interrupt_turn: 4,
               start_turn_request: 3,
               start_review_request: 3
             ]}

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, Keyword.take(opts, [:name]))
  end

  @spec connect(keyword()) :: GenServer.on_start()
  def connect(opts \\ []), do: start_link(opts)

  @spec disconnect(t(), term(), timeout()) :: :ok
  def disconnect(client, reason \\ :normal, timeout \\ @default_timeout) do
    GenServer.stop(client_server(client), reason, timeout)
  end

  @spec subscribe(t(), pid()) :: :ok | {:error, {:client_call_failed, term()}}
  def subscribe(client, subscriber \\ self()) when is_pid(subscriber) do
    subscribe(client, subscriber, [])
  end

  @spec subscribe(t(), pid(), keyword()) :: :ok | {:error, {:client_call_failed, term()}}
  def subscribe(client, subscriber, opts) when is_pid(subscriber) and is_list(opts) do
    thread_id = Keyword.get(opts, :thread_id, :all)
    reconciles_replay_gap? = Keyword.get(opts, :reconciles_replay_gap?, false)

    client
    |> client_server()
    |> safe_client_call(
      {:subscribe, subscriber, thread_id, reconciles_replay_gap?},
      @default_timeout
    )
    |> normalize_ok_reply()
  end

  @spec unsubscribe(t(), pid()) :: :ok | {:error, {:client_call_failed, term()}}
  def unsubscribe(client, subscriber \\ self()) when is_pid(subscriber) do
    client
    |> client_server()
    |> safe_client_call({:unsubscribe, subscriber}, @default_timeout)
    |> normalize_ok_reply()
  end

  @doc """
  Subscribes the caller to active-thread signals from shared Codex clients.

  Requires a `Phoenix.PubSub` server configured as `config :codex_ex, :pubsub`.
  """
  @spec subscribe_thread_activity() ::
          :ok | {:error, :pubsub_not_configured | {:already_registered, pid()}}
  def subscribe_thread_activity do
    case thread_activity_pubsub() do
      nil -> {:error, :pubsub_not_configured}
      pubsub -> Phoenix.PubSub.subscribe(pubsub, @thread_activity_topic)
    end
  end

  @doc "Publishes active threads already loaded by the connected app server."
  @spec broadcast_active_threads(t()) :: :ok | {:error, term()}
  def broadcast_active_threads(client) do
    case safe_client_call(client_server(client), :thread_activity_origin, @default_timeout) do
      {:ok, {origin_client, runner_id, workspace_id} = origin}
      when is_pid(origin_client) and (is_binary(runner_id) or is_nil(runner_id)) and
             (is_binary(workspace_id) or is_nil(workspace_id)) ->
        broadcast_active_thread_pages(client, origin, nil, %{})

      {:error, _reason} = error ->
        error

      other ->
        {:error, {:unexpected_client_reply, other}}
    end
  end

  @spec register_request_handler(t(), (term() -> term()) | nil) ::
          :ok | {:error, {:client_call_failed, term()}}
  def register_request_handler(client, handler) when is_function(handler, 1) or is_nil(handler) do
    client
    |> client_server()
    |> safe_client_call({:register_request_handler, handler}, @default_timeout)
    |> normalize_ok_reply()
  end

  @spec initialize_result(t()) ::
          {:ok, initialize_response()} | {:error, {:client_call_failed, term()}}
  def initialize_result(client) do
    client
    |> client_server()
    |> safe_client_call(:initialize_result, @default_timeout)
    |> normalize_initialize_result_reply()
  end

  @spec pending_requests(t()) :: {:ok, [term()]} | {:error, term()}
  def pending_requests(client) do
    client
    |> client_server()
    |> safe_client_call(:pending_requests, @default_timeout)
    |> normalize_pending_requests_reply()
  end

  @doc "Queues replay-gap acknowledgement on the client generation that reported it."
  @spec acknowledge_replay_gap_async(pid(), pid(), non_neg_integer()) :: :ok
  def acknowledge_replay_gap_async(client, owner, through_sequence)
      when is_pid(client) and is_pid(owner) and is_integer(through_sequence) and through_sequence >= 0 do
    GenServer.cast(client, {:acknowledge_replay_gap, owner, through_sequence})
  end

  @spec list_experimental_features(t(), map()) ::
          {:ok, experimental_feature_list_response()}
          | {:error, {:client_call_failed, term()} | term()}
  def list_experimental_features(client, params \\ %{}) when is_map(params) do
    client
    |> client_server()
    |> safe_client_call(
      {:experimental_feature_list, ExperimentalFeatureListParams.decode(params), @default_timeout},
      call_timeout_for(@default_timeout)
    )
    |> normalize_experimental_feature_list_result()
  end

  @spec set_experimental_feature_enablement(t(), map()) ::
          {:ok, experimental_feature_enablement_set_response()}
          | {:error, {:client_call_failed, term()} | term()}
  def set_experimental_feature_enablement(client, enablement) when is_map(enablement) do
    params =
      ExperimentalFeatureEnablementSetParams.decode(%{
        "enablement" => MapHelpers.deep_stringify_keys(enablement)
      })

    client
    |> client_server()
    |> safe_client_call(
      {:experimental_feature_enablement_set, params, @default_timeout},
      call_timeout_for(@default_timeout)
    )
    |> normalize_experimental_feature_enablement_set_result()
  end

  @spec list_hooks(t(), [binary()]) ::
          {:ok, hooks_list_response()} | {:error, {:client_call_failed, term()} | term()}
  def list_hooks(client, cwds \\ []) when is_list(cwds) do
    client
    |> client_server()
    |> safe_client_call(
      {:hooks_list, %HooksListParams{cwds: cwds}, @default_timeout},
      call_timeout_for(@default_timeout)
    )
    |> normalize_hooks_list_result()
  end

  @spec trust_hook(t(), binary(), binary(), timeout()) ::
          {:ok, config_write_response()} | {:error, {:client_call_failed, term()} | term()}
  def trust_hook(client, hook_key, current_hash, timeout \\ @default_timeout)
      when is_binary(hook_key) and is_binary(current_hash) and (is_integer(timeout) or timeout == :infinity) do
    client
    |> client_server()
    |> safe_client_call(
      {:config_batch_write, hook_trust_params(hook_key, current_hash), timeout},
      call_timeout_for(timeout)
    )
    |> normalize_config_write_result()
  end

  @spec set_hook_enabled(t(), binary(), boolean(), timeout()) ::
          {:ok, config_write_response()} | {:error, {:client_call_failed, term()} | term()}
  def set_hook_enabled(client, hook_key, enabled?, timeout \\ @default_timeout)
      when is_binary(hook_key) and is_boolean(enabled?) and (is_integer(timeout) or timeout == :infinity) do
    client
    |> client_server()
    |> safe_client_call(
      {:config_batch_write, hook_enabled_params(hook_key, enabled?), timeout},
      call_timeout_for(timeout)
    )
    |> normalize_config_write_result()
  end

  @spec reply_request(t(), term(), request_result(), timeout()) :: :ok | {:error, term()}
  def reply_request(client, request_id, reply, timeout \\ @default_timeout) do
    client
    |> client_server()
    |> safe_client_call({:reply_request, request_id, reply, timeout}, call_timeout_for(timeout))
    |> normalize_empty_result()
  end

  @spec list_models(t()) ::
          {:ok, model_list_response()} | {:error, {:client_call_failed, term()} | term()}
  def list_models(client) do
    client
    |> client_server()
    |> safe_client_call(
      {:model_list, ModelListParams.decode(%{}), @default_timeout},
      call_timeout_for(@default_timeout)
    )
    |> normalize_model_list_result()
  end

  @spec list_skills(t(), map()) ::
          {:ok, skills_list_response()} | {:error, {:client_call_failed, term()} | term()}
  def list_skills(client, params \\ %{}) when is_map(params) do
    client
    |> client_server()
    |> safe_client_call(
      {:skills_list, SkillsListParams.decode(params), @default_timeout},
      call_timeout_for(@default_timeout)
    )
    |> normalize_skills_list_result()
  end

  @doc "Reads one MCP resource in the active thread's server scope."
  @spec read_mcp_resource(GenServer.server(), binary(), binary(), binary()) ::
          {:ok, mcp_resource_read_response()} | {:error, term()}
  def read_mcp_resource(client, thread_id, server, uri)
      when is_binary(thread_id) and is_binary(server) and is_binary(uri) do
    params = %McpResourceReadParams{server: server, thread_id: thread_id, uri: uri}

    client
    |> client_server()
    |> safe_client_call(
      {:mcp_resource_read, params, @default_timeout},
      call_timeout_for(@default_timeout)
    )
    |> normalize_mcp_resource_read_result()
  end

  @doc "Calls one MCP tool in the active thread's server scope."
  @spec call_mcp_tool(GenServer.server(), binary(), binary(), binary(), map()) ::
          {:ok, mcp_server_tool_call_response()} | {:error, term()}
  def call_mcp_tool(client, thread_id, server, tool, arguments)
      when is_binary(thread_id) and is_binary(server) and is_binary(tool) and is_map(arguments) do
    params = %McpServerToolCallParams{
      arguments: arguments,
      server: server,
      thread_id: thread_id,
      tool: tool
    }

    client
    |> client_server()
    |> safe_client_call(
      {:mcp_server_tool_call, params, @default_timeout},
      call_timeout_for(@default_timeout)
    )
    |> normalize_mcp_server_tool_call_result()
  end

  @spec list_threads(t(), map()) ::
          {:ok, thread_list_response()} | {:error, {:client_call_failed, term()} | term()}
  def list_threads(client, params \\ %{}) when is_map(params) do
    client
    |> client_server()
    |> safe_client_call(
      {:thread_list, build_thread_list_params(params), @default_timeout},
      call_timeout_for(@default_timeout)
    )
    |> normalize_thread_list_result()
  end

  @spec start_fuzzy_file_search_session(t(), binary(), [binary()]) ::
          {:ok, :started} | {:error, {:client_call_failed, term()} | term()}
  def start_fuzzy_file_search_session(client, session_id, roots) when is_binary(session_id) and is_list(roots) do
    client
    |> client_server()
    |> safe_client_call(
      {:fuzzy_file_search_session_start, %FuzzyFileSearchSessionStartParams{session_id: session_id, roots: roots},
       @default_timeout},
      call_timeout_for(@default_timeout)
    )
    |> normalize_fuzzy_file_search_session_start_result()
  end

  @spec update_fuzzy_file_search_session(t(), binary(), binary()) ::
          {:ok, :updated} | {:error, {:client_call_failed, term()} | term()}
  def update_fuzzy_file_search_session(client, session_id, query) when is_binary(session_id) and is_binary(query) do
    client
    |> client_server()
    |> safe_client_call(
      {:fuzzy_file_search_session_update, %FuzzyFileSearchSessionUpdateParams{session_id: session_id, query: query},
       @default_timeout},
      call_timeout_for(@default_timeout)
    )
    |> normalize_fuzzy_file_search_session_update_result()
  end

  @spec stop_fuzzy_file_search_session(t(), binary()) ::
          :ok | {:error, {:client_call_failed, term()} | term()}
  def stop_fuzzy_file_search_session(client, session_id) when is_binary(session_id) do
    client
    |> client_server()
    |> safe_client_call(
      {:fuzzy_file_search_session_stop, %FuzzyFileSearchSessionStopParams{session_id: session_id}, @default_timeout},
      call_timeout_for(@default_timeout)
    )
    |> normalize_fuzzy_file_search_session_stop_result()
  end

  @spec start_thread(t(), map()) :: {:ok, Thread.t()} | {:error, term()}
  def start_thread(client, params \\ %{}) when is_map(params) do
    with {:ok, settings_seed} <- resolve_thread_settings_seed(client, params) do
      params = build_thread_start_params(params, settings_seed)

      client
      |> client_server()
      |> safe_client_call(
        {:thread_start, params, settings_seed, @default_timeout},
        call_timeout_for(@default_timeout)
      )
      |> normalize_thread_call_result()
    end
  end

  @spec resume_thread(t(), binary(), map(), keyword()) ::
          {:ok, thread_response()} | {:error, term()}
  def resume_thread(client, thread_id, overrides \\ %{}, opts \\ [])
      when is_binary(thread_id) and is_map(overrides) and is_list(opts) do
    client = client_server(client)

    with {:ok, settings_seed} <- resume_thread_settings_seed(client, overrides, opts),
         {:ok, overrides} <- apply_thread_settings_seed(overrides, settings_seed) do
      params = build_thread_resume_params(thread_id, overrides)

      client
      |> safe_client_call(
        {:thread_resume, params, settings_seed, @default_timeout},
        call_timeout_for(@default_timeout)
      )
      |> normalize_thread_call_result()
    end
  end

  @doc "Reads the effective Codex configuration for a working directory."
  @spec read_config(t(), binary() | nil) :: {:ok, config_read_response()} | {:error, term()}
  def read_config(client, cwd) when is_binary(cwd) or is_nil(cwd) do
    with {:ok, {%ConfigReadResponse{} = response, _raw_config}} <-
           read_config_source(client, cwd) do
      {:ok, response}
    end
  end

  defp read_config_source(client, cwd) when is_binary(cwd) or is_nil(cwd) do
    params = %ConfigReadParams{cwd: cwd, include_layers: false}

    client
    |> client_server()
    |> safe_client_call(
      {:config_read, params, @default_timeout},
      call_timeout_for(@default_timeout)
    )
    |> normalize_config_read_source_result()
  end

  @spec read_thread(t(), binary(), keyword()) :: {:ok, ThreadSnapshot.t()} | {:error, term()}
  def read_thread(client, thread_id, opts \\ []) when is_binary(thread_id) and is_list(opts) do
    params = build_thread_read_params(thread_id, opts)
    history_mode = Keyword.get(opts, :history_mode)

    timeout =
      if Keyword.get(opts, :include_turns, false),
        do: @thread_history_timeout,
        else: @default_timeout

    client
    |> client_server()
    |> safe_client_call(
      {:thread_read, params, history_mode, timeout},
      call_timeout_for(timeout)
    )
    |> normalize_thread_snapshot_call_result()
  end

  @doc "Lists one page of a paginated thread's turns in the requested server order."
  @spec list_thread_turns(t(), binary(), keyword()) ::
          {:ok, thread_turns_page()} | {:error, term()}
  def list_thread_turns(client, thread_id, opts \\ []) when is_binary(thread_id) and is_list(opts) do
    cursor = Keyword.get(opts, :cursor)
    limit = Keyword.get(opts, :limit, @thread_turns_page_size)

    if (is_nil(cursor) or is_binary(cursor)) and is_integer(limit) and limit > 0 do
      params = %ThreadTurnsListParams{
        cursor: cursor,
        items_view: "full",
        limit: limit,
        sort_direction: "desc",
        thread_id: thread_id
      }

      client
      |> client_server()
      |> safe_client_call(
        {:thread_turns_list, params, @thread_history_timeout},
        call_timeout_for(@thread_history_timeout)
      )
      |> normalize_thread_turns_page_result()
    else
      {:error, :invalid_thread_turns_page_options}
    end
  end

  @spec fork_thread(t(), binary(), map()) :: {:ok, Thread.t()} | {:error, term()}
  def fork_thread(client, thread_id, overrides \\ %{}) when is_binary(thread_id) and is_map(overrides) do
    params = build_thread_fork_params(thread_id, overrides)
    settings_seed = settings_seed_from_params(overrides)

    client
    |> client_server()
    |> safe_client_call(
      {:thread_fork, params, settings_seed, @default_timeout},
      call_timeout_for(@default_timeout)
    )
    |> normalize_thread_call_result()
  end

  @doc "Injects model-visible history items without starting a turn."
  @spec inject_thread_items(t(), binary(), [map()]) :: :ok | {:error, term()}
  def inject_thread_items(client, thread_id, items) when is_binary(thread_id) and is_list(items) do
    params = %ThreadInjectItemsParams{
      items: Enum.map(items, &MapHelpers.deep_stringify_keys/1),
      thread_id: thread_id
    }

    client
    |> client_server()
    |> safe_client_call(
      {:thread_inject_items, params, @default_timeout},
      call_timeout_for(@default_timeout)
    )
    |> normalize_empty_result()
  end

  @doc "Unsubscribes the app-server connection from a remote thread."
  @spec unsubscribe_thread(t(), binary()) ::
          {:ok, struct()} | {:error, term()}
  def unsubscribe_thread(client, thread_id) when is_binary(thread_id) do
    params = %ThreadUnsubscribeParams{thread_id: thread_id}

    client
    |> client_server()
    |> safe_client_call(
      {:thread_unsubscribe, params, @default_timeout},
      call_timeout_for(@default_timeout)
    )
    |> normalize_thread_unsubscribe_result()
  end

  # Replies come from the external GenServer boundary; Dialyzer cannot prove the
  # decoded struct satisfies the complete public Thread type.
  @dialyzer {:nowarn_function, revert_thread: 3}
  @spec revert_thread(t(), binary(), binary()) :: {:ok, Thread.t()} | {:error, term()}
  def revert_thread(client, thread_id, before_turn_id) when is_binary(thread_id) and is_binary(before_turn_id) do
    params = %ThreadRevertParams{thread_id: thread_id, before_turn_id: before_turn_id}

    client
    |> client_server()
    |> safe_client_call(
      {:thread_revert, params, @default_timeout},
      call_timeout_for(@default_timeout)
    )
    |> normalize_thread_call_result()
  end

  @spec archive_thread(t(), binary()) :: :ok | {:error, term()}
  def archive_thread(client, thread_id) when is_binary(thread_id) do
    client
    |> client_server()
    |> safe_client_call(
      {:thread_archive, %ThreadArchiveParams{thread_id: thread_id}, @default_timeout},
      call_timeout_for(@default_timeout)
    )
    |> normalize_empty_result()
  end

  @spec set_thread_name(t(), binary(), binary()) :: :ok | {:error, term()}
  def set_thread_name(client, thread_id, name) when is_binary(thread_id) and is_binary(name) do
    params = %ThreadSetNameParams{thread_id: thread_id, name: name}

    client
    |> client_server()
    |> safe_client_call(
      {:thread_name_set, params, @default_timeout},
      call_timeout_for(@default_timeout)
    )
    |> normalize_empty_result()
  end

  @spec start_thread_compaction(t(), binary()) :: :ok | {:error, term()}
  def start_thread_compaction(client, thread_id) when is_binary(thread_id) do
    client
    |> client_server()
    |> safe_client_call(
      {:thread_compact_start, %ThreadCompactStartParams{thread_id: thread_id}, @default_timeout},
      call_timeout_for(@default_timeout)
    )
    |> normalize_empty_result()
  end

  @spec rollback_thread(t(), binary(), non_neg_integer()) :: {:ok, Thread.t()} | {:error, term()}
  def rollback_thread(client, thread_id, num_turns)
      when is_binary(thread_id) and is_integer(num_turns) and num_turns >= 1 do
    client
    |> client_server()
    |> safe_client_call(
      {:thread_rollback, %ThreadRollbackParams{thread_id: thread_id, num_turns: num_turns}, @thread_history_timeout},
      call_timeout_for(@thread_history_timeout)
    )
    |> normalize_thread_call_result()
  end

  @spec set_thread_goal(t(), binary(), map()) :: {:ok, ThreadGoal.t()} | {:error, term()}
  def set_thread_goal(client, thread_id, attrs) when is_binary(thread_id) and is_map(attrs) do
    params = build_thread_goal_set_params(thread_id, attrs)

    client
    |> client_server()
    |> safe_client_call(
      {:thread_goal_set, params, @default_timeout},
      call_timeout_for(@default_timeout)
    )
    |> normalize_thread_goal_call_result()
  end

  @spec get_thread_goal(t(), binary()) :: {:ok, ThreadGoal.t() | nil} | {:error, term()}
  def get_thread_goal(client, thread_id) when is_binary(thread_id) do
    client
    |> client_server()
    |> safe_client_call(
      {:thread_goal_get, %ThreadGoalGetParams{thread_id: thread_id}, @default_timeout},
      call_timeout_for(@default_timeout)
    )
    |> normalize_thread_goal_get_call_result()
  end

  @spec clear_thread_goal(t(), binary()) :: :ok | {:error, term()}
  def clear_thread_goal(client, thread_id) when is_binary(thread_id) do
    client
    |> client_server()
    |> safe_client_call(
      {:thread_goal_clear, %ThreadGoalClearParams{thread_id: thread_id}, @default_timeout},
      call_timeout_for(@default_timeout)
    )
    |> normalize_empty_result()
  end

  @spec start_review(t(), binary(), map(), binary() | nil, boolean()) ::
          {:ok, TurnStream.t()} | {:error, term()}
  def start_review(
        client,
        thread_id,
        target \\ %{"type" => "uncommittedChanges"},
        delivery \\ nil,
        direct_stream? \\ true
      )
      when is_binary(thread_id) and is_map(target) and (is_binary(delivery) or is_nil(delivery)) and
             is_boolean(direct_stream?) do
    params = %ReviewStartParams{thread_id: thread_id, target: target, delivery: delivery}

    TurnStream.start_request(
      client,
      thread_id,
      fn ->
        start_review_request(client, params, @turn_timeout)
      end,
      direct_stream?
    )
  end

  @spec unarchive_thread(t(), binary()) :: {:ok, Thread.t()} | {:error, term()}
  def unarchive_thread(client, thread_id) when is_binary(thread_id) do
    client
    |> client_server()
    |> safe_client_call(
      {:thread_unarchive, %ThreadUnarchiveParams{thread_id: thread_id}, @default_timeout},
      call_timeout_for(@default_timeout)
    )
    |> normalize_thread_call_result()
  end

  @spec start_realtime(t(), binary(), binary()) :: :ok | {:error, term()}
  def start_realtime(client, thread_id, sdp) when is_binary(thread_id) and is_binary(sdp) do
    params = %ThreadRealtimeStartParams{
      thread_id: thread_id,
      output_modality: "audio",
      transport: %{"type" => "webrtc", "sdp" => sdp},
      version: "v3"
    }

    client
    |> client_server()
    |> safe_client_call(
      {:thread_realtime_start, params, @default_timeout},
      call_timeout_for(@default_timeout)
    )
    |> normalize_empty_result()
  end

  @spec stop_realtime(t(), binary()) :: :ok | {:error, term()}
  def stop_realtime(client, thread_id) when is_binary(thread_id) do
    client
    |> client_server()
    |> safe_client_call(
      {:thread_realtime_stop, %ThreadRealtimeStopParams{thread_id: thread_id}, @default_timeout},
      call_timeout_for(@default_timeout)
    )
    |> normalize_empty_result()
  end

  @spec run(t(), binary(), [map()], map(), boolean()) ::
          {:ok, TurnStream.t()} | {:error, term()}
  def run(client, thread_id, input, opts \\ %{}, direct_stream? \\ true)
      when is_binary(thread_id) and is_list(input) and is_map(opts) and is_boolean(direct_stream?) do
    params = build_turn_start_params(thread_id, input, opts)

    TurnStream.start(client, thread_id, params, direct_stream?)
  end

  @doc "Starts a turn and returns its initial protocol state without collecting its event stream."
  @spec start_turn(t(), binary(), [map()], map()) :: {:ok, Turn.t()} | {:error, term()}
  def start_turn(client, thread_id, input, opts \\ %{}) when is_binary(thread_id) and is_list(input) and is_map(opts) do
    start_turn_request(client, build_turn_start_params(thread_id, input, opts), @default_timeout)
  end

  @spec run_text(t(), binary(), binary(), map()) :: {:ok, binary()} | {:error, term()}
  def run_text(client, thread_id, text, opts \\ %{}) when is_binary(thread_id) and is_binary(text) and is_map(opts) do
    with {:ok, stream} <- run(client, thread_id, [%{"type" => "text", "text" => text}], opts),
         {:ok, stream} <- TurnStream.wait(stream, @turn_timeout),
         :ok <- TurnStream.ensure_success(stream) do
      {:ok, stream.final_text}
    end
  end

  @spec run_json(t(), binary(), binary(), map(), map()) :: {:ok, term()} | {:error, term()}
  def run_json(client, thread_id, text, output_schema, opts \\ %{})
      when is_binary(thread_id) and is_binary(text) and is_map(output_schema) and is_map(opts) do
    opts =
      opts
      |> MapHelpers.deep_stringify_keys()
      |> Map.put("outputSchema", MapHelpers.deep_stringify_keys(output_schema))

    with {:ok, stream} <- run(client, thread_id, [%{"type" => "text", "text" => text}], opts),
         {:ok, stream} <- TurnStream.wait(stream, @turn_timeout),
         :ok <- TurnStream.ensure_success(stream) do
      TurnStream.final_json(stream)
    end
  end

  @spec steer_turn(t(), binary(), binary(), [map()], binary(), timeout()) ::
          {:ok, binary()} | {:error, term()}
  def steer_turn(client, thread_id, expected_turn_id, input, client_message_id, timeout \\ @default_timeout)
      when is_binary(thread_id) and is_binary(expected_turn_id) and is_list(input) and is_binary(client_message_id) and
             (is_integer(timeout) or timeout == :infinity) do
    params = build_turn_steer_params(thread_id, expected_turn_id, input, client_message_id)

    client
    |> client_server()
    |> safe_client_call({:turn_steer, params, timeout}, call_timeout_for(timeout))
    |> normalize_turn_steer_call_result()
  end

  @spec interrupt_turn(t(), binary(), binary(), timeout()) ::
          {:ok, turn_interrupt_response()} | {:error, term()}
  def interrupt_turn(client, thread_id, turn_id, timeout \\ @default_timeout)
      when is_binary(thread_id) and is_binary(turn_id) and (is_integer(timeout) or timeout == :infinity) do
    params = %TurnInterruptParams{thread_id: thread_id, turn_id: turn_id}

    client
    |> client_server()
    |> safe_client_call({:turn_interrupt, params, timeout}, call_timeout_for(timeout))
    |> normalize_turn_interrupt_call_result()
  end

  @spec start_turn_request(t(), map(), timeout()) :: {:ok, Turn.t()} | {:error, term()}
  def start_turn_request(client, params, timeout \\ @turn_timeout)
      when is_map(params) and (is_integer(timeout) or timeout == :infinity) do
    client
    |> client_server()
    |> safe_client_call({:turn_start_request, params, timeout}, call_timeout_for(timeout))
    |> normalize_turn_start_call_result()
  end

  @spec start_review_request(t(), map(), timeout()) :: {:ok, Turn.t()} | {:error, term()}
  def start_review_request(client, params, timeout \\ @turn_timeout)
      when is_map(params) and (is_integer(timeout) or timeout == :infinity) do
    client
    |> client_server()
    |> safe_client_call({:review_start_request, params, timeout}, call_timeout_for(timeout))
    |> normalize_turn_start_call_result()
  end

  @impl true
  @spec init(keyword()) :: {:ok, state()} | {:stop, term()}
  def init(opts) do
    Process.flag(:trap_exit, true)

    initialize_params =
      opts
      |> Keyword.get(:initialize_params, %{})
      |> build_initialize_params()

    session_opts =
      opts
      |> Keyword.drop([:name, :initialize_params, :subscriber, :broadcasts_thread_activity?])
      |> Keyword.put(:notification_target, self())

    with {:ok, subscribers} <- initial_subscribers(opts),
         {:ok, session} <- Session.start_link(session_opts),
         {:ok, result} <- Session.initialize(session, initialize_params),
         {:ok, initialize_result} <- normalize_initialize_result({:ok, result}) do
      {:ok,
       %{
         session: session,
         subscribers: subscribers,
         initialize_result: initialize_result,
         model_list_cache: nil,
         model_list_pending: nil,
         pending_requests: %{},
         replay_gap: nil,
         replay_gap_owners: MapSet.new(),
         broadcasts_thread_activity?: Keyword.get(opts, :broadcasts_thread_activity?, false),
         thread_activity_runner_id: Keyword.get(opts, :runner_id),
         thread_activity_workspace_id: Keyword.get(opts, :workspace_id),
         request_handler: Keyword.get(opts, :request_handler),
         strict_protocol: Keyword.get(opts, :strict_protocol, false)
       }}
    else
      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def handle_cast({:acknowledge_replay_gap, owner, through_sequence}, state)
      when is_pid(owner) and is_integer(through_sequence) and through_sequence >= 0 do
    state = handle_async_replay_gap_ack(state, owner, through_sequence)
    {:noreply, state}
  end

  @impl true
  def handle_call(:initialize_result, _from, state) do
    {:reply, {:ok, state.initialize_result}, state}
  end

  def handle_call(:thread_activity_origin, _from, state) do
    {:reply, {:ok, {self(), state.thread_activity_runner_id, state.thread_activity_workspace_id}}, state}
  end

  @impl true
  def handle_call(:pending_requests, _from, state) do
    {:reply, {:ok, Map.values(state.pending_requests)}, state}
  end

  def handle_call({:subscribe, subscriber, thread_id, reconciles_replay_gap?}, _from, state)
      when (is_binary(thread_id) or is_nil(thread_id) or thread_id == :all) and is_boolean(reconciles_replay_gap?) do
    case Map.fetch(state.subscribers, subscriber) do
      {:ok, %{thread_id: ^thread_id, reconciles_replay_gap?: ^reconciles_replay_gap?}} ->
        {:reply, :ok, state}

      {:ok, subscription} ->
        subscription = %{
          subscription
          | thread_id: thread_id,
            reconciles_replay_gap?: reconciles_replay_gap?
        }

        state =
          state
          |> put_in([:subscribers, subscriber], subscription)
          |> remove_replay_gap_owner(subscriber)

        state =
          state
          |> replay_gap_and_pending_requests(subscriber)
          |> maybe_complete_abandoned_replay_gap()

        {:reply, :ok, state}

      :error ->
        state =
          put_in(state, [:subscribers, subscriber], %{
            monitor_ref: Process.monitor(subscriber),
            thread_id: thread_id,
            reconciles_replay_gap?: reconciles_replay_gap?
          })

        state =
          state
          |> replay_gap_and_pending_requests(subscriber)
          |> maybe_complete_abandoned_replay_gap()

        {:reply, :ok, state}
    end
  end

  @impl true
  def handle_call({:unsubscribe, subscriber}, _from, state) do
    {:reply, :ok, remove_subscriber(state, subscriber)}
  end

  @impl true
  def handle_call({:register_request_handler, handler}, _from, state) do
    {:reply, :ok, %{state | request_handler: handler}}
  end

  @impl true
  def handle_call({:reply_request, request_id, reply, timeout}, _from, state) do
    case normalize_request_reply(reply) do
      {:ok, normalized_reply} ->
        case Session.respond(state.session, request_id, normalized_reply, timeout) do
          :ok ->
            {:reply, :ok, resolve_replied_request(state, request_id)}

          {:error, _reason} = error ->
            {:reply, error, state}
        end

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:config_read, %ConfigReadParams{} = params, timeout}, from, state) do
    defer_session_request(from, state, "config/read", params, timeout, fn payload ->
      case ConfigReadResponse.decode(payload) do
        %ConfigReadResponse{} = response ->
          {:ok, {response, Map.get(payload, "config")}}

        _other ->
          {:error, {:protocol_error, {:unexpected_config_read_result, payload}}}
      end
    end)
  end

  @impl true
  def handle_call({:thread_start, params, settings_seed, timeout}, from, state) do
    client = self()

    defer_session_request(from, state, "thread/start", params, timeout, fn result ->
      normalize_thread_result({:ok, result}, client, settings_seed)
    end)
  end

  @impl true
  def handle_call({:thread_resume, params, settings_seed, timeout}, from, state) do
    client = self()

    :ok =
      defer_reply(from, state.session, fn session ->
        session
        |> Session.request("thread/resume", params, timeout)
        |> require_initial_turns_page(params)
        |> normalize_thread_result(client, settings_seed)
      end)

    {:noreply, state}
  end

  @impl true
  def handle_call({:thread_read, params, history_mode, timeout}, from, state) do
    :ok =
      defer_reply(from, state.session, fn session ->
        read_thread_snapshot(session, params, history_mode, timeout)
      end)

    {:noreply, state}
  end

  @impl true
  def handle_call({:thread_turns_list, params, timeout}, from, state) do
    :ok =
      defer_reply(from, state.session, fn session ->
        request_thread_turns_page(session, params, timeout)
      end)

    {:noreply, state}
  end

  @impl true
  def handle_call({:model_list, _params, _timeout}, _from, %{model_list_cache: cache} = state) when not is_nil(cache) do
    {:reply, {:ok, cache}, state}
  end

  def handle_call({:model_list, _params, _timeout}, from, %{model_list_pending: pending} = state) when is_map(pending) do
    next_pending = Map.update!(pending, :callers, &[from | &1])
    {:noreply, %{state | model_list_pending: next_pending}}
  end

  def handle_call({:model_list, params, timeout}, from, state) do
    ref = make_ref()
    client = self()

    case start_model_list_request(client, ref, state.session, params, timeout) do
      :ok ->
        {:noreply, %{state | model_list_pending: %{ref: ref, callers: [from]}}}

      {:error, _reason} = error ->
        {:reply, error, state}
    end
  end

  @impl true
  def handle_call({request, params, timeout}, from, state) when is_map_key(@simple_requests, request) do
    {method, response} = Map.fetch!(@simple_requests, request)

    defer_session_request(from, state, method, params, timeout, fn payload ->
      simple_request_success(payload, response)
    end)
  end

  @impl true
  def handle_call({:thread_fork, params, settings_seed, timeout}, from, state) do
    client = self()
    thread_id = ProtocolValue.get(params, :thread_id, nil, ["threadId"])

    :ok =
      defer_reply(from, state.session, fn session ->
        read_params = %ThreadReadParams{thread_id: thread_id, include_turns: false}

        with {:ok, snapshot} <- read_thread_metadata(session, read_params, timeout),
             :ok <- require_paginated_history_mode(snapshot.history_mode) do
          session
          |> Session.request("thread/fork", params, timeout)
          |> normalize_thread_result(client, settings_seed)
        end
      end)

    {:noreply, state}
  end

  @impl true
  def handle_call({:thread_inject_items, %ThreadInjectItemsParams{} = params, timeout}, from, state) do
    defer_session_request(from, state, "thread/inject_items", params, timeout, fn payload ->
      case ThreadInjectItemsResponse.decode(payload) do
        %ThreadInjectItemsResponse{} -> :ok
        _other -> {:error, {:protocol_error, {:unexpected_thread_inject_items_result, payload}}}
      end
    end)
  end

  @impl true
  def handle_call({:thread_unsubscribe, %ThreadUnsubscribeParams{} = params, timeout}, from, state) do
    defer_session_request(from, state, "thread/unsubscribe", params, timeout, fn payload ->
      case ThreadUnsubscribeResponse.decode(payload) do
        %ThreadUnsubscribeResponse{} = response -> {:ok, response}
        _other -> {:error, {:protocol_error, {:unexpected_thread_unsubscribe_result, payload}}}
      end
    end)
  end

  @impl true
  def handle_call({:thread_revert, %ThreadRevertParams{} = params, timeout}, from, state) do
    client = self()

    :ok =
      defer_reply(from, state.session, fn session ->
        read_params = %ThreadReadParams{thread_id: params.thread_id, include_turns: false}

        with {:ok, snapshot} <- read_thread_metadata(session, read_params, timeout),
             :ok <- require_paginated_history_mode(snapshot.history_mode) do
          session
          |> Session.request("thread/revert", params, timeout)
          |> normalize_thread_result(client)
        end
      end)

    {:noreply, state}
  end

  @impl true
  def handle_call({:thread_rollback, params, timeout}, from, state) do
    client = self()
    thread_id = ProtocolValue.get(params, :thread_id, nil, ["threadId"])

    :ok =
      defer_reply(from, state.session, fn session ->
        read_params = %ThreadReadParams{thread_id: thread_id, include_turns: true}

        with {:ok, preflight_snapshot} <- read_thread_metadata(session, read_params, timeout),
             :ok <- require_paginated_history_mode(preflight_snapshot.history_mode),
             {:ok, result} <- Session.request(session, "thread/rollback", params, timeout) do
          case normalize_thread_result({:ok, result}, client) do
            {:ok, %Thread{} = thread} ->
              {:ok, thread}

            {:error, reason} ->
              {:error, {:thread_rollback_applied_but_refresh_failed, reason}}
          end
        end
      end)

    {:noreply, state}
  end

  @impl true
  def handle_call({:thread_unarchive, params, timeout}, from, state) do
    client = self()

    defer_session_request(from, state, "thread/unarchive", params, timeout, fn result ->
      normalize_thread_result({:ok, result}, client)
    end)
  end

  @impl true
  def handle_call({:turn_start_request, params, timeout}, from, state) do
    thread_id = ProtocolValue.get(params, :thread_id, nil, ["threadId"])

    defer_session_request(from, state, "turn/start", params, timeout, fn result ->
      normalize_turn_result(result, thread_id)
    end)
  end

  @impl true
  def handle_call({:review_start_request, params, timeout}, from, state) do
    thread_id = ProtocolValue.get(params, :thread_id, nil, ["threadId"])

    defer_session_request(from, state, "review/start", params, timeout, fn result ->
      normalize_review_result(result, thread_id)
    end)
  end

  @impl true
  def handle_call({:turn_steer, params, timeout}, from, state) do
    defer_session_request(from, state, "turn/steer", params, timeout, fn result ->
      normalize_turn_steer_result(result)
    end)
  end

  @impl true
  def handle_call({:turn_interrupt, params, timeout}, from, state) do
    defer_session_request(from, state, "turn/interrupt", params, timeout, fn result ->
      normalize_turn_interrupt_result(result)
    end)
  end

  @impl true
  def handle_info({:codex_app_server_notification, payload}, state) do
    handle_notification(payload, nil, state)
  end

  def handle_info({:codex_app_server_notification, payload, sequence}, state)
      when is_integer(sequence) and sequence >= 0 do
    handle_notification(payload, sequence, state)
  end

  @impl true
  def handle_info({:codex_app_server_request, payload}, state) do
    handle_server_request(payload, nil, state)
  end

  def handle_info({:codex_app_server_request, payload, sequence}, state) when is_integer(sequence) and sequence >= 0 do
    handle_server_request(payload, sequence, state)
  end

  @impl true
  def handle_info({:codex_app_server_unmatched_response, payload}, state) do
    handle_unmatched_response(payload, nil, state)
  end

  def handle_info({:codex_app_server_unmatched_response, payload, sequence}, state)
      when is_integer(sequence) and sequence >= 0 do
    handle_unmatched_response(payload, sequence, state)
  end

  @impl true
  def handle_info({:codex_app_server_sequence_handled, sequence}, state) when is_integer(sequence) and sequence >= 0 do
    {:noreply, acknowledge_transport_sequence(state, sequence)}
  end

  @impl true
  def handle_info({:codex_app_server_transport_closed, _reason, sequence}, state)
      when is_integer(sequence) and sequence >= 0 do
    {:noreply, acknowledge_transport_sequence(state, sequence)}
  end

  @impl true
  def handle_info({:codex_app_server_replay_gap, payload}, state) when is_map(payload) do
    {:noreply, install_replay_gap(state, payload)}
  end

  @impl true
  def handle_info({:request_handler_replied, request_id}, state) do
    {:noreply, resolve_replied_request(state, request_id)}
  end

  @impl true
  def handle_info({:model_list_result, ref, reply}, %{model_list_pending: %{ref: ref, callers: callers}} = state) do
    Enum.each(callers, &GenServer.reply(&1, reply))

    state =
      state
      |> Map.put(:model_list_pending, nil)
      |> maybe_cache_model_list_reply(reply)

    {:noreply, state}
  end

  @impl true
  def handle_info({:EXIT, session, reason}, %{session: session} = state) do
    {:stop, session_exit_reason(reason), state}
  end

  @impl true
  def handle_info({:DOWN, monitor_ref, :process, subscriber, _reason}, state) do
    case Map.fetch(state.subscribers, subscriber) do
      {:ok, %{monitor_ref: ^monitor_ref}} ->
        {:noreply, remove_subscriber(state, subscriber)}

      _ ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_info(_message, state), do: {:noreply, state}

  @impl true
  def terminate(_reason, %{session: session}) when is_pid(session) do
    if Process.alive?(session), do: Session.stop(session)
    :ok
  end

  defp session_exit_reason(:normal), do: :normal
  defp session_exit_reason(:shutdown), do: :shutdown
  defp session_exit_reason({:shutdown, _reason} = reason), do: reason
  defp session_exit_reason(reason), do: {:session_exited, reason}

  defp initial_subscribers(opts) do
    case Keyword.fetch(opts, :subscriber) do
      {:ok, subscriber} when is_pid(subscriber) ->
        {:ok,
         %{
           subscriber => %{
             monitor_ref: Process.monitor(subscriber),
             thread_id: :all,
             reconciles_replay_gap?: false
           }
         }}

      {:ok, subscriber} ->
        {:error, {:invalid_subscriber, subscriber}}

      :error ->
        {:ok, %{}}
    end
  end

  @doc "Builds normalized app-server initialization parameters with required client capabilities."
  @spec build_initialize_params(map()) :: map()
  def build_initialize_params(params) when is_map(params) do
    params =
      params
      |> MapHelpers.deep_stringify_keys()
      |> Map.put_new("clientInfo", @default_client_info)
      |> Map.put_new("capabilities", %{})

    client_info =
      params
      |> Map.get("clientInfo", @default_client_info)
      |> MapHelpers.deep_stringify_keys()
      |> Map.put_new("name", @default_client_info["name"])
      |> Map.put_new("version", @default_client_info["version"])

    capabilities =
      params
      |> Map.get("capabilities", %{})
      |> MapHelpers.deep_stringify_keys()
      |> Map.put_new("experimentalApi", true)

    params
    |> Map.put("clientInfo", client_info)
    |> Map.put("capabilities", capabilities)
    |> InitializeParams.decode()
    |> InitializeParams.encode()
  end

  defp build_thread_start_params(params, settings_seed) when is_map(params) and is_map(settings_seed) do
    params =
      params
      |> MapHelpers.deep_stringify_keys()
      |> Map.put("developerInstructions", settings_seed.developer_instructions)
      |> Map.put_new("historyMode", "paginated")
      |> enable_realtime()

    params
    |> ThreadStartParams.decode()
    |> ThreadStartParams.encode()
    |> Map.merge(Map.take(params, ["serviceTier"]))
    |> merge_mock_passthrough(params, @thread_start_mock_keys)
  end

  defp build_thread_resume_params(thread_id, overrides) when is_binary(thread_id) and is_map(overrides) do
    params =
      overrides
      |> MapHelpers.deep_stringify_keys()
      |> Map.put("threadId", thread_id)
      |> enable_realtime()

    params
    |> ThreadResumeParams.decode()
    |> ThreadResumeParams.encode()
    |> Map.merge(Map.take(params, ["developerInstructions", "serviceTier"]))
    |> merge_mock_passthrough(params, @thread_resume_mock_keys)
  end

  defp build_thread_read_params(thread_id, opts) when is_binary(thread_id) and is_list(opts) do
    ThreadReadParams.decode(%{
      "threadId" => thread_id,
      "includeTurns" => Keyword.get(opts, :include_turns, false)
    })
  end

  defp build_thread_fork_params(thread_id, overrides) when is_binary(thread_id) and is_map(overrides) do
    params =
      overrides
      |> MapHelpers.deep_stringify_keys()
      |> Map.put("excludeTurns", true)
      |> Map.put("threadSource", "appServer")
      |> Map.put("threadId", thread_id)
      |> enable_realtime()

    params
    |> ThreadForkParams.decode()
    |> ThreadForkParams.encode()
    |> Map.merge(Map.take(params, ["beforeTurnId", "developerInstructions", "serviceTier"]))
  end

  defp enable_realtime(%{"config" => config} = params) when is_map(config) do
    Map.put(params, "config", Map.put_new(config, @realtime_feature, true))
  end

  defp enable_realtime(%{"config" => nil} = params), do: Map.put(params, "config", %{@realtime_feature => true})

  defp enable_realtime(params), do: Map.put_new(params, "config", %{@realtime_feature => true})

  defp build_thread_goal_set_params(thread_id, attrs) when is_binary(thread_id) and is_map(attrs) do
    attrs
    |> MapHelpers.deep_stringify_keys()
    |> Map.put("threadId", thread_id)
    |> ThreadGoalSetParams.decode()
  end

  defp build_turn_start_params(thread_id, input, opts) when is_binary(thread_id) and is_list(input) and is_map(opts) do
    params =
      opts
      |> MapHelpers.deep_stringify_keys()
      |> Map.put("threadId", thread_id)
      |> Map.put("input", Enum.map(input, &MapHelpers.deep_stringify_keys/1))

    params
    |> TurnStartParams.decode()
    |> TurnStartParams.encode()
    |> merge_mock_passthrough(params, @turn_start_mock_keys)
  end

  defp build_thread_list_params(params) when is_map(params) do
    params
    |> MapHelpers.deep_stringify_keys()
    |> ThreadListParams.decode()
    |> ThreadListParams.encode()
  end

  defp hook_trust_params(hook_key, current_hash) when is_binary(hook_key) and is_binary(current_hash) do
    hook_state_params(hook_key, %{"trusted_hash" => current_hash})
  end

  defp hook_enabled_params(hook_key, enabled?) when is_binary(hook_key) and is_boolean(enabled?) do
    hook_state_params(hook_key, %{"enabled" => enabled?})
  end

  defp hook_state_params(hook_key, attrs) when is_binary(hook_key) and is_map(attrs) do
    %ConfigBatchWriteParams{
      edits: [
        %ConfigEdit{
          key_path: "hooks.state",
          merge_strategy: "upsert",
          value: %{hook_key => attrs}
        }
      ],
      reload_user_config: true
    }
  end

  defp build_turn_steer_params(thread_id, expected_turn_id, input, client_message_id)
       when is_binary(thread_id) and is_binary(expected_turn_id) and is_list(input) and is_binary(client_message_id) do
    TurnSteerParams.decode(%{
      "threadId" => thread_id,
      "expectedTurnId" => expected_turn_id,
      "clientUserMessageId" => client_message_id,
      "input" => Enum.map(input, &MapHelpers.deep_stringify_keys/1)
    })
  end

  defp merge_mock_passthrough(encoded_params, raw_params, keys)
       when is_map(encoded_params) and is_map(raw_params) and is_list(keys) do
    Map.merge(encoded_params, Map.take(raw_params, keys))
  end

  defp normalize_initialize_result({:ok, %{} = payload}) do
    {:ok, InitializeResponse.decode(payload)}
  end

  defp normalize_initialize_result({:ok, payload}) do
    {:error, {:protocol_error, {:unexpected_initialize_result, payload}}}
  end

  defp normalize_thread_result(result, client), do: normalize_thread_result(result, client, nil)

  defp normalize_thread_result({:ok, %{} = payload}, client, settings_seed) do
    case ProtocolValue.get(payload, :thread) do
      %{} = thread ->
        build_thread(client, thread, payload, settings_seed)

      _other ->
        {:error, {:protocol_error, {:unexpected_thread_result, payload}}}
    end
  end

  defp normalize_thread_result({:ok, payload}, _client, _settings_seed) do
    {:error, {:protocol_error, {:unexpected_thread_result, payload}}}
  end

  defp normalize_thread_result({:error, _reason} = error, _client, _settings_seed), do: error

  defp require_initial_turns_page({:ok, payload} = result, params) when is_map(payload) and is_map(params) do
    case {
      ProtocolValue.get(params, :initial_turns_page),
      ProtocolValue.get(payload, :initial_turns_page)
    } do
      {%{}, nil} -> {:error, {:protocol_error, :missing_initial_turns_page}}
      _other -> result
    end
  end

  defp require_initial_turns_page(result, _params), do: result

  defp build_thread(client, thread, options_source, settings_seed) do
    with {:ok, snapshot} <- ThreadSnapshot.from_protocol(thread),
         {:ok, turns} <- initial_thread_turns(options_source, snapshot) do
      snapshot = %{snapshot | turns: turns}
      settings = ThreadSettings.from_protocol(options_source, settings_seed)
      {:ok, Thread.new(client, snapshot, settings)}
    else
      {:error, {:protocol_error, _reason}} = error -> error
      {:error, reason} -> {:error, {:protocol_error, reason}}
    end
  end

  defp initial_thread_turns(options_source, %ThreadSnapshot{} = snapshot) do
    case ProtocolValue.get(options_source, :initial_turns_page) do
      nil ->
        {:ok, snapshot.turns}

      page when is_map(page) ->
        decode_paginated_turns(ProtocolValue.get(page, :data), snapshot.id)

      other ->
        {:error, {:protocol_error, {:unexpected_initial_turns_page, other}}}
    end
  end

  defp resolve_thread_settings_seed(client, params) when is_map(params) do
    params = MapHelpers.deep_stringify_keys(params)
    cwd = Map.get(params, "cwd")

    with {:ok, {%ConfigReadResponse{config: %ConfigReadResponse.Config{} = config}, raw_config}}
         when is_map(raw_config) <- read_config_source(client, cwd),
         {:ok, developer_instructions} <-
           effective_optional_binary(
             params,
             "developerInstructions",
             config.developer_instructions
           ),
         {:ok, reasoning_summary} <-
           effective_config_value(
             params,
             "model_reasoning_summary",
             config.model_reasoning_summary
           ),
         {:ok, personality} <-
           effective_optional_binary(params, "personality", Map.get(raw_config, "personality")) do
      {:ok,
       %{
         developer_instructions: developer_instructions,
         personality: personality,
         reasoning_summary: reasoning_summary
       }}
    else
      {:ok, {%ConfigReadResponse{}, _raw_config}} ->
        {:error, {:protocol_error, :missing_effective_config}}

      {:error, _reason} = error ->
        error
    end
  end

  defp resume_thread_settings_seed(_client, _params, opts) do
    case Keyword.fetch(opts, :settings_seed) do
      {:ok, nil} -> {:ok, nil}
      {:ok, seed} -> normalize_persisted_settings_seed(seed)
      :error -> {:ok, nil}
    end
  end

  defp normalize_persisted_settings_seed(seed) when is_map(seed) do
    case ThreadSettings.decode_persisted_seed(seed) do
      {:ok, settings_seed} ->
        {:ok, settings_seed}

      {:error, :invalid_thread_settings_seed} ->
        {:error, {:protocol_error, :invalid_persisted_thread_settings_seed}}
    end
  end

  defp normalize_persisted_settings_seed(_seed), do: {:error, {:protocol_error, :invalid_persisted_thread_settings_seed}}

  defp settings_seed_from_params(params) when is_map(params) do
    params = MapHelpers.deep_stringify_keys(params)
    config = Map.get(params, "config")
    reasoning_summary = if is_map(config), do: Map.get(config, "model_reasoning_summary")
    personality = if is_map(config), do: Map.get(config, "personality")

    with {:ok, developer_instructions} <- Map.fetch(params, "developerInstructions"),
         true <- is_nil(developer_instructions) or is_binary(developer_instructions),
         true <- is_nil(personality) or is_binary(personality),
         true <- is_nil(reasoning_summary) or is_binary(reasoning_summary) do
      %{
        developer_instructions: developer_instructions,
        personality: personality,
        reasoning_summary: reasoning_summary
      }
    else
      _other -> nil
    end
  end

  defp effective_optional_binary(params, key, configured) do
    value = if Map.has_key?(params, key), do: Map.get(params, key), else: configured

    if is_nil(value) or is_binary(value),
      do: {:ok, value},
      else: {:error, {:protocol_error, {:invalid_effective_config, key}}}
  end

  defp effective_config_value(params, key, configured) do
    config = Map.get(params, "config", %{})

    value =
      if is_map(config),
        do: Map.get(config, key, configured),
        else: configured

    if is_nil(value) or is_binary(value),
      do: {:ok, value},
      else: {:error, {:protocol_error, {:invalid_effective_config, key}}}
  end

  defp apply_thread_settings_seed(params, nil) when is_map(params), do: {:ok, params}

  defp apply_thread_settings_seed(params, settings_seed) when is_map(params) and is_map(settings_seed) do
    persisted_seed = %{
      "developerInstructions" => settings_seed.developer_instructions,
      "personality" => settings_seed.personality,
      "reasoningSummary" => settings_seed.reasoning_summary
    }

    case ThreadSettings.put_persisted_seed(MapHelpers.deep_stringify_keys(params), persisted_seed) do
      {:ok, params} ->
        {:ok, params}

      {:error, :invalid_thread_settings_seed} ->
        {:error, {:protocol_error, :invalid_thread_resume_config}}
    end
  end

  defp normalize_thread_snapshot_result({:ok, %{} = payload}) do
    case ProtocolValue.get(payload, :thread) do
      %{} = thread ->
        case ThreadSnapshot.from_protocol(thread) do
          {:ok, snapshot} -> {:ok, snapshot}
          {:error, reason} -> {:error, {:protocol_error, reason}}
        end

      _other ->
        {:error, {:protocol_error, {:unexpected_thread_result, payload}}}
    end
  end

  defp normalize_thread_snapshot_result({:ok, payload}) do
    {:error, {:protocol_error, {:unexpected_thread_result, payload}}}
  end

  defp normalize_thread_snapshot_result({:error, _reason} = error), do: error

  defp read_thread_snapshot(session, %ThreadReadParams{include_turns: true} = params, history_mode, timeout)
       when history_mode in ["paginated", nil] do
    with {:ok, snapshot} <- read_thread_metadata(session, params, timeout),
         :ok <- require_paginated_history_mode(snapshot.history_mode) do
      load_paginated_turns(session, snapshot, timeout)
    end
  end

  defp read_thread_snapshot(_session, %ThreadReadParams{include_turns: true}, history_mode, _timeout),
    do: unsupported_history_mode(history_mode)

  defp read_thread_snapshot(session, %ThreadReadParams{} = params, _history_mode, timeout) do
    request_thread_snapshot(session, params, timeout)
  end

  defp read_thread_metadata(session, %ThreadReadParams{} = params, timeout) do
    request_thread_snapshot(session, %{params | include_turns: false}, timeout)
  end

  defp request_thread_snapshot(session, %ThreadReadParams{} = params, timeout) do
    session
    |> Session.request("thread/read", params, timeout)
    |> normalize_thread_snapshot_result()
  end

  defp load_paginated_turns(session, %ThreadSnapshot{id: thread_id} = snapshot, timeout) do
    case list_paginated_turns(session, thread_id, nil, [], %{}, timeout) do
      {:ok, turns} ->
        {:ok, %{snapshot | turns: turns}}

      {:error, {:remote_error, remote_error}} = error ->
        if paginated_history_unmaterialized?(remote_error), do: {:ok, snapshot}, else: error

      {:error, _reason} = error ->
        error
    end
  end

  defp paginated_history_unmaterialized?(%{"code" => -32_600, "message" => message}) when is_binary(message) do
    String.contains?(message, "thread/turns/list is unavailable before first user message")
  end

  defp paginated_history_unmaterialized?(_remote_error), do: false

  defp list_paginated_turns(session, thread_id, cursor, acc, seen_cursors, timeout) do
    with {:ok, seen_cursors} <- remember_thread_turns_cursor(cursor, seen_cursors) do
      request_next_paginated_turns_page(
        session,
        thread_id,
        cursor,
        acc,
        seen_cursors,
        timeout
      )
    end
  end

  defp request_next_paginated_turns_page(session, thread_id, cursor, acc, seen_cursors, timeout) do
    params = %ThreadTurnsListParams{
      cursor: cursor,
      items_view: "full",
      limit: @thread_turns_page_size,
      sort_direction: "desc",
      thread_id: thread_id
    }

    case request_thread_turns_page(session, params, timeout) do
      {:ok, %{turns: turns, next_cursor: next_cursor}} ->
        acc = Enum.reduce(turns, acc, &[&1 | &2])

        case next_cursor do
          nil ->
            {:ok, acc}

          next_cursor when is_binary(next_cursor) and turns == [] ->
            {:error, {:protocol_error, :empty_thread_turns_page_with_cursor}}

          next_cursor when is_binary(next_cursor) ->
            list_paginated_turns(session, thread_id, next_cursor, acc, seen_cursors, timeout)
        end

      {:error, _reason} = error ->
        error
    end
  end

  defp remember_thread_turns_cursor(nil, seen_cursors), do: {:ok, seen_cursors}

  defp remember_thread_turns_cursor(cursor, seen_cursors) when is_binary(cursor) do
    if Map.has_key?(seen_cursors, cursor),
      do: {:error, {:protocol_error, {:repeated_thread_turns_cursor, cursor}}},
      else: {:ok, Map.put(seen_cursors, cursor, true)}
  end

  defp request_thread_turns_page(session, %ThreadTurnsListParams{} = params, timeout) do
    case Session.request(session, "thread/turns/list", params, timeout) do
      {:ok, %{} = payload} ->
        response = ThreadTurnsListResponse.decode(payload)

        with {:ok, turns} <- decode_paginated_turns(response.data, params.thread_id),
             :ok <- validate_thread_turns_cursor(response.next_cursor) do
          {:ok, %{turns: turns, next_cursor: response.next_cursor}}
        end

      {:ok, other} ->
        {:error, {:protocol_error, {:unexpected_thread_turns_result, other}}}

      {:error, _reason} = error ->
        error
    end
  end

  defp validate_thread_turns_cursor(cursor) when is_binary(cursor) or is_nil(cursor), do: :ok

  defp validate_thread_turns_cursor(cursor), do: {:error, {:protocol_error, {:invalid_thread_turns_cursor, cursor}}}

  defp normalize_thread_turns_page_result({:ok, %{turns: turns, next_cursor: next_cursor}})
       when is_list(turns) and (is_binary(next_cursor) or is_nil(next_cursor)),
       do: {:ok, %{turns: turns, next_cursor: next_cursor}}

  defp normalize_thread_turns_page_result({:error, _reason} = error), do: error

  defp normalize_thread_turns_page_result(other),
    do: {:error, {:protocol_error, {:unexpected_thread_turns_page_result, other}}}

  defp unsupported_history_mode(history_mode), do: {:error, {:unsupported_thread_history_mode, history_mode}}

  defp require_paginated_history_mode("paginated"), do: :ok
  defp require_paginated_history_mode(history_mode), do: unsupported_history_mode(history_mode)

  defp decode_paginated_turns(turns, thread_id) when is_list(turns) do
    turns
    |> Enum.reduce_while({:ok, []}, fn turn, {:ok, acc} ->
      case Turn.from_protocol(turn, thread_id) do
        {:ok, parsed_turn} -> {:cont, {:ok, [parsed_turn | acc]}}
        {:error, reason} -> {:halt, {:error, {:protocol_error, reason}}}
      end
    end)
    |> case do
      {:ok, parsed_turns} -> {:ok, Enum.reverse(parsed_turns)}
      {:error, _reason} = error -> error
    end
  end

  defp decode_paginated_turns(other, _thread_id), do: {:error, {:protocol_error, {:unexpected_thread_turns_data, other}}}

  defp decode_thread_list_snapshots(threads) when is_list(threads) do
    threads
    |> Enum.reduce_while({:ok, []}, fn thread, {:ok, acc} ->
      case ThreadSnapshot.from_protocol(thread) do
        {:ok, snapshot} -> {:cont, {:ok, [snapshot | acc]}}
        {:error, reason} -> {:halt, {:error, {:protocol_error, reason}}}
      end
    end)
    |> case do
      {:ok, snapshots} -> {:ok, Enum.reverse(snapshots)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp decode_thread_list_snapshots(other), do: {:error, {:protocol_error, {:unexpected_thread_list_result, other}}}

  defp normalize_turn_result(payload, thread_id), do: normalize_parsed_turn(payload, thread_id, :unexpected_turn_result)

  defp normalize_review_result(payload, thread_id),
    do: normalize_parsed_turn(payload, thread_id, :unexpected_review_result)

  defp normalize_parsed_turn(%{} = payload, thread_id, unexpected_tag) when is_binary(thread_id) do
    case ProtocolValue.get(payload, :turn) do
      %{} = turn ->
        case Turn.from_protocol(turn, thread_id) do
          {:ok, parsed_turn} -> {:ok, parsed_turn}
          {:error, reason} -> {:error, {:protocol_error, reason}}
        end

      _other ->
        {:error, {:protocol_error, {unexpected_tag, payload}}}
    end
  end

  defp normalize_parsed_turn(payload, _thread_id, unexpected_tag),
    do: {:error, {:protocol_error, {unexpected_tag, payload}}}

  defp normalize_turn_steer_result(%{} = payload) do
    case TurnSteerResponse.decode(payload) do
      %{turn_id: turn_id} when is_binary(turn_id) -> {:ok, turn_id}
      _decoded -> {:error, {:protocol_error, {:unexpected_turn_steer_result, payload}}}
    end
  end

  defp normalize_turn_steer_result(payload) do
    {:error, {:protocol_error, {:unexpected_turn_steer_result, payload}}}
  end

  defp normalize_turn_interrupt_result(%{} = payload) do
    case TurnInterruptResponse.decode(payload) do
      %TurnInterruptResponse{} = decoded -> {:ok, decoded}
      _decoded -> {:error, {:protocol_error, {:unexpected_turn_interrupt_result, payload}}}
    end
  end

  defp normalize_turn_interrupt_result(payload) do
    {:error, {:protocol_error, {:unexpected_turn_interrupt_result, payload}}}
  end

  defp normalize_ok_reply(:ok), do: :ok
  defp normalize_ok_reply({:error, {:client_call_failed, _reason}} = error), do: error
  defp normalize_ok_reply(other), do: {:error, {:client_call_failed, {:unexpected_reply, other}}}

  defp normalize_initialize_result_reply({:ok, %InitializeResponse{} = result}), do: {:ok, result}

  defp normalize_initialize_result_reply({:error, {:client_call_failed, _reason}} = error), do: error

  defp normalize_initialize_result_reply(other), do: {:error, {:client_call_failed, {:unexpected_reply, other}}}

  defp normalize_pending_requests_reply({:ok, requests}) when is_list(requests), do: {:ok, requests}

  defp normalize_pending_requests_reply({:error, {:client_call_failed, _reason}} = error), do: error

  defp normalize_pending_requests_reply(other), do: {:error, {:client_call_failed, {:unexpected_reply, other}}}

  defp normalize_request_reply({:ok, payload}), do: {:ok, {:ok, payload}}

  defp normalize_request_reply({:error, _reason} = error), do: {:ok, error}

  defp normalize_request_reply(other), do: {:error, {:unsupported_request_reply, other}}

  defp normalize_model_list_result(result), do: normalize_struct_result(result, ModelListResponse)

  defp normalize_experimental_feature_list_result(result),
    do: normalize_struct_result(result, ExperimentalFeatureListResponse)

  defp normalize_experimental_feature_enablement_set_result(result),
    do: normalize_struct_result(result, ExperimentalFeatureEnablementSetResponse)

  defp normalize_skills_list_result(result), do: normalize_struct_result(result, SkillsListResponse)

  defp normalize_mcp_resource_read_result({:ok, %McpResourceReadResponse{} = response}), do: {:ok, response}

  defp normalize_mcp_resource_read_result({:error, _reason} = error), do: error

  defp normalize_mcp_resource_read_result(other), do: {:error, {:unexpected_client_reply, other}}

  defp normalize_mcp_server_tool_call_result({:ok, %McpServerToolCallResponse{} = response}), do: {:ok, response}

  defp normalize_mcp_server_tool_call_result({:error, _reason} = error), do: error

  defp normalize_mcp_server_tool_call_result(other), do: {:error, {:unexpected_client_reply, other}}

  defp normalize_hooks_list_result(result), do: normalize_struct_result(result, HooksListResponse)

  defp normalize_config_write_result(result), do: normalize_struct_result(result, ConfigWriteResponse)

  defp normalize_thread_list_result({:ok, %ThreadListResponse{} = result}) do
    with {:ok, snapshots} <- decode_thread_list_snapshots(result.data) do
      {:ok, %{data: snapshots, next_cursor: result.next_cursor}}
    end
  end

  defp normalize_thread_list_result({:error, _reason} = error), do: error
  defp normalize_thread_list_result(other), do: {:error, {:unexpected_client_reply, other}}

  defp normalize_fuzzy_file_search_session_start_result(result) do
    with {:ok, _response} <- normalize_struct_result(result, FuzzyFileSearchSessionStartResponse),
         do: {:ok, :started}
  end

  defp normalize_fuzzy_file_search_session_update_result(result) do
    with {:ok, _response} <- normalize_struct_result(result, FuzzyFileSearchSessionUpdateResponse),
         do: {:ok, :updated}
  end

  defp normalize_fuzzy_file_search_session_stop_result(result) do
    with {:ok, _response} <- normalize_struct_result(result, FuzzyFileSearchSessionStopResponse),
         do: :ok
  end

  defp normalize_thread_call_result({:ok, %Thread{client: client, id: id, settings: settings, snapshot: snapshot}}),
    do: {:ok, %Thread{client: client, id: id, settings: settings, snapshot: snapshot}}

  defp normalize_thread_call_result({:error, _reason} = error), do: error

  defp normalize_thread_call_result(other), do: {:error, {:unexpected_client_reply, other}}

  defp normalize_config_read_source_result(
         {:ok, {%ConfigReadResponse{config: config, layers: layers, origins: origins}, raw_config}}
       ), do: {:ok, {%ConfigReadResponse{config: config, layers: layers, origins: origins}, raw_config}}

  defp normalize_config_read_source_result({:error, _reason} = error), do: error

  defp normalize_config_read_source_result(other), do: {:error, {:unexpected_client_reply, other}}

  defp normalize_thread_snapshot_call_result(result), do: normalize_struct_result(result, ThreadSnapshot)

  defp normalize_struct_result({:ok, result}, module) when is_struct(result, module), do: {:ok, result}

  defp normalize_struct_result({:error, _reason} = error, _module), do: error

  defp normalize_struct_result(other, _module), do: {:error, {:unexpected_client_reply, other}}

  defp normalize_thread_goal_call_result({:ok, %ThreadGoalSetResponse{goal: goal}}) do
    case ThreadGoal.from_protocol(goal) do
      {:ok, %ThreadGoal{} = parsed_goal} -> {:ok, parsed_goal}
      {:error, reason} -> {:error, {:protocol_error, reason}}
    end
  end

  defp normalize_thread_goal_call_result({:error, _reason} = error), do: error

  defp normalize_thread_goal_call_result(other), do: {:error, {:unexpected_client_reply, other}}

  defp normalize_thread_goal_get_call_result({:ok, %ThreadGoalGetResponse{goal: nil}}), do: {:ok, nil}

  defp normalize_thread_goal_get_call_result({:ok, %ThreadGoalGetResponse{goal: goal}}) do
    case ThreadGoal.from_protocol(goal) do
      {:ok, %ThreadGoal{} = parsed_goal} -> {:ok, parsed_goal}
      {:error, reason} -> {:error, {:protocol_error, reason}}
    end
  end

  defp normalize_thread_goal_get_call_result({:error, _reason} = error), do: error

  defp normalize_thread_goal_get_call_result(other), do: {:error, {:unexpected_client_reply, other}}

  defp normalize_empty_result(:ok), do: :ok
  defp normalize_empty_result({:error, _reason} = error), do: error
  defp normalize_empty_result(other), do: {:error, {:unexpected_client_reply, other}}

  defp normalize_thread_unsubscribe_result({:ok, %ThreadUnsubscribeResponse{} = response}), do: {:ok, response}

  defp normalize_thread_unsubscribe_result({:error, _reason} = error), do: error

  defp normalize_thread_unsubscribe_result(other), do: {:error, {:unexpected_client_reply, other}}

  defp normalize_turn_steer_call_result({:ok, turn_id}) when is_binary(turn_id), do: {:ok, turn_id}

  defp normalize_turn_steer_call_result({:error, _reason} = error), do: error
  defp normalize_turn_steer_call_result(other), do: {:error, {:unexpected_client_reply, other}}

  defp normalize_turn_interrupt_call_result(result), do: normalize_struct_result(result, TurnInterruptResponse)

  defp normalize_turn_start_call_result(result), do: normalize_struct_result(result, Turn)

  defp handle_notification(payload, sequence, state) do
    case Parser.parse(:notification, payload, strict_protocol: state.strict_protocol) do
      {:ok, message} ->
        state = resolve_pending_request(state, message)

        _ =
          if state.broadcasts_thread_activity? do
            maybe_broadcast_thread_activity(
              message,
              {self(), state.thread_activity_runner_id, state.thread_activity_workspace_id}
            )
          end

        broadcast(matching_subscribers(state.subscribers, message), message)
        {:noreply, acknowledge_transport_sequence(state, sequence)}

      {:error, reason} ->
        broadcast_protocol_error(state.subscribers, reason, payload)
        {:noreply, acknowledge_transport_sequence(state, sequence)}
    end
  end

  defp handle_server_request(payload, sequence, state) do
    case Parser.parse(:request, payload, strict_protocol: state.strict_protocol) do
      {:ok, message} ->
        state = track_pending_request(state, message)
        broadcast(matching_subscribers(state.subscribers, message), message)
        maybe_handle_request(message, state)
        {:noreply, acknowledge_transport_sequence(state, sequence)}

      {:error, {:unknown_method, :request, method} = reason} ->
        broadcast_protocol_error(state.subscribers, reason, payload)
        maybe_reject_unknown_request(payload, method, state)
        {:noreply, acknowledge_transport_sequence(state, sequence)}

      {:error, reason} ->
        broadcast_protocol_error(state.subscribers, reason, payload)
        {:noreply, acknowledge_transport_sequence(state, sequence)}
    end
  end

  defp handle_unmatched_response(payload, sequence, state) do
    message = %UnmatchedResponse{id: Map.get(payload, "id"), payload: payload}
    broadcast(matching_subscribers(state.subscribers, message), message)
    {:noreply, acknowledge_transport_sequence(state, sequence)}
  end

  defp broadcast(subscribers, event) do
    Enum.each(Map.keys(subscribers), fn subscriber ->
      send(subscriber, {:codex_app_server_event, event})
    end)
  end

  defp broadcast_protocol_error(subscribers, reason, payload) do
    Enum.each(Map.keys(subscribers), fn subscriber ->
      send(subscriber, {:codex_app_server_protocol_error, reason, payload})
    end)
  end

  defp maybe_broadcast_thread_activity(
         %ServerNotification{method: "thread/started", params: %ThreadStartedNotification{thread: thread}},
         origin
       ) do
    with {:ok, %ThreadSnapshot{} = snapshot} <- ThreadSnapshot.from_protocol(thread),
         false <- snapshot.source == "appServer",
         false <- snapshot.thread_source == "appServer",
         false <- ThreadSnapshot.subagent?(snapshot) do
      broadcast_thread_discovered(origin, snapshot)
    else
      _ignored -> :ok
    end
  end

  defp maybe_broadcast_thread_activity(
         %ServerNotification{
           method: "thread/status/changed",
           params: %ThreadStatusChangedNotification{thread_id: thread_id, status: status}
         },
         origin
       )
       when is_binary(thread_id) do
    if ProtocolValue.get(status, :type) == "active" do
      broadcast_thread_active(origin, thread_id)
    else
      :ok
    end
  end

  defp maybe_broadcast_thread_activity(_message, _origin), do: :ok

  defp broadcast_active_thread_pages(client, origin, cursor, seen_cursors) do
    params = %{
      "archived" => false,
      "cursor" => cursor,
      "limit" => @thread_activity_page_size,
      "sortDirection" => "desc",
      "sortKey" => "recency_at",
      "sourceKinds" => ["cli", "vscode", "exec", "appServer", "unknown"],
      "useStateDbOnly" => true
    }

    with {:ok, %{data: snapshots, next_cursor: next_cursor}} <- list_threads(client, params) do
      Enum.each(snapshots, fn
        %ThreadSnapshot{id: thread_id, status: "active"} when is_binary(thread_id) ->
          broadcast_thread_active(origin, thread_id)

        _inactive ->
          :ok
      end)

      continue_active_thread_pages(client, origin, next_cursor, seen_cursors)
    end
  end

  defp continue_active_thread_pages(_client, _origin, nil, _seen_cursors), do: :ok

  defp continue_active_thread_pages(client, origin, cursor, seen_cursors) when is_binary(cursor) do
    if Map.has_key?(seen_cursors, cursor) do
      {:error, {:protocol_error, {:repeated_thread_list_cursor, cursor}}}
    else
      broadcast_active_thread_pages(
        client,
        origin,
        cursor,
        Map.put(seen_cursors, cursor, true)
      )
    end
  end

  defp continue_active_thread_pages(_client, _origin, cursor, _seen_cursors),
    do: {:error, {:protocol_error, {:invalid_thread_list_cursor, cursor}}}

  defp broadcast_thread_active(origin, thread_id) when is_binary(thread_id) do
    broadcast_thread_activity({:codex_thread_active, origin, thread_id})
  end

  defp broadcast_thread_discovered(origin, %ThreadSnapshot{} = snapshot) do
    broadcast_thread_activity({:codex_thread_discovered, origin, snapshot})
  end

  defp broadcast_thread_activity(message) do
    case thread_activity_pubsub() do
      nil -> :ok
      pubsub -> Phoenix.PubSub.broadcast(pubsub, @thread_activity_topic, message)
    end
  end

  defp thread_activity_pubsub, do: Application.get_env(:codex_ex, :pubsub)

  defp track_pending_request(state, message) do
    case Message.request_id(message) do
      nil -> state
      request_id -> put_in(state.pending_requests[request_id], message)
    end
  end

  defp resolve_pending_request(state, message) do
    case Message.resolved_request_id(message) do
      nil -> state
      request_id -> delete_pending_request(state, request_id)
    end
  end

  defp delete_pending_request(state, request_id) do
    %{state | pending_requests: Map.delete(state.pending_requests, request_id)}
  end

  defp resolve_replied_request(state, request_id), do: delete_pending_request(state, request_id)

  defp acknowledge_transport_sequence(state, nil), do: state

  defp acknowledge_transport_sequence(state, sequence) when is_integer(sequence) and sequence >= 0 do
    :ok = Session.acknowledge_transport_sequence(state.session, sequence)
    state
  end

  defp replay_gap_and_pending_requests(state, subscriber) when is_pid(subscriber) do
    state
    |> replay_gap(subscriber)
    |> replay_pending_requests(subscriber)
  end

  defp replay_pending_requests(state, subscriber) do
    Enum.each(state.pending_requests, fn {_request_id, request} ->
      if subscriber_accepts_message?(state.subscribers[subscriber], request) do
        send(subscriber, {:codex_app_server_event, request})
      end
    end)

    state
  end

  defp replay_gap(%{replay_gap: replay_gap} = state, subscriber) when is_pid(subscriber) and is_map(replay_gap) do
    subscription = state.subscribers[subscriber]
    send(subscriber, {:codex_app_server_replay_gap, self(), replay_gap})

    if subscription.reconciles_replay_gap? do
      %{state | replay_gap_owners: MapSet.put(state.replay_gap_owners, subscriber)}
    else
      state
    end
  end

  defp replay_gap(state, _subscriber), do: state

  defp handle_async_replay_gap_ack(state, owner, through_sequence) do
    with %{"missing_through_sequence" => missing_through_sequence}
         when is_integer(missing_through_sequence) <- state.replay_gap,
         true <- through_sequence >= missing_through_sequence,
         true <- MapSet.member?(state.replay_gap_owners, owner) do
      owners = MapSet.delete(state.replay_gap_owners, owner)

      if MapSet.size(owners) == 0 do
        complete_replay_gap(%{state | replay_gap_owners: owners}, through_sequence)
      else
        %{state | replay_gap_owners: owners}
      end
    else
      _other -> state
    end
  end

  defp complete_replay_gap(state, through_sequence) do
    case Session.acknowledge_replay_gap(state.session, through_sequence) do
      :ok ->
        %{state | replay_gap: nil, replay_gap_owners: MapSet.new()}

      {:error, _reason} ->
        state
    end
  end

  defp remove_subscriber(state, subscriber) do
    case Map.pop(state.subscribers, subscriber) do
      {nil, _subscribers} ->
        state

      {%{monitor_ref: monitor_ref}, subscribers} ->
        Process.demonitor(monitor_ref, [:flush])

        state
        |> Map.put(:subscribers, subscribers)
        |> remove_replay_gap_owner(subscriber)
        |> maybe_complete_abandoned_replay_gap()
    end
  end

  defp remove_replay_gap_owner(state, subscriber) do
    %{state | replay_gap_owners: MapSet.delete(state.replay_gap_owners, subscriber)}
  end

  defp maybe_complete_abandoned_replay_gap(%{replay_gap: nil} = state), do: state

  defp maybe_complete_abandoned_replay_gap(state) do
    current_owners = replay_gap_reconcilers(state.subscribers)

    if MapSet.size(state.replay_gap_owners) == 0 and MapSet.size(current_owners) > 0 do
      case state.replay_gap do
        %{"missing_through_sequence" => through_sequence} when is_integer(through_sequence) ->
          complete_replay_gap(state, through_sequence)

        _other ->
          state
      end
    else
      state
    end
  end

  defp matching_subscribers(subscribers, message) do
    Map.filter(subscribers, fn {_subscriber, subscription} ->
      subscriber_accepts_message?(subscription, message)
    end)
  end

  defp subscriber_accepts_message?(%{thread_id: thread_id}, message) when is_binary(thread_id) do
    case Message.thread_id(message) do
      nil -> true
      message_thread_id -> message_thread_id == thread_id
    end
  end

  defp subscriber_accepts_message?(%{thread_id: nil}, message), do: is_nil(Message.thread_id(message))

  defp subscriber_accepts_message?(%{thread_id: :all}, _message), do: true

  defp subscriber_accepts_message?(_subscription, _message), do: false

  defp replay_gap_reconcilers(subscribers) do
    Enum.reduce(subscribers, MapSet.new(), fn
      {subscriber, %{reconciles_replay_gap?: true}}, owners -> MapSet.put(owners, subscriber)
      {_subscriber, _subscription}, owners -> owners
    end)
  end

  defp install_replay_gap(state, payload) when is_map(payload) do
    Enum.each(Map.keys(state.subscribers), fn subscriber ->
      send(subscriber, {:codex_app_server_replay_gap, self(), payload})
    end)

    %{state | replay_gap: payload, replay_gap_owners: replay_gap_reconcilers(state.subscribers)}
  end

  defp defer_session_request(from, state, method, params, timeout, on_success)
       when is_binary(method) and is_function(on_success, 1) do
    :ok =
      defer_reply(from, state.session, fn session ->
        case Session.request(session, method, params, timeout) do
          {:ok, result} -> on_success.(result)
          {:error, _reason} = error -> error
        end
      end)

    {:noreply, state}
  end

  defp simple_request_success(_payload, :discard_response), do: :ok

  defp simple_request_success(payload, response_module) when is_atom(response_module),
    do: {:ok, response_module.decode(payload)}

  defp defer_reply(from, session, fun) do
    :ok =
      start_async_child(fn ->
        reply = run_deferred(fun, session)
        GenServer.reply(from, reply)
      end)

    :ok
  end

  defp start_model_list_request(client, ref, session, params, timeout) do
    start_async_child(fn ->
      reply =
        run_deferred(
          fn session ->
            case Session.request(session, "model/list", params, timeout) do
              {:ok, %{} = payload} -> {:ok, ModelListResponse.decode(payload)}
              {:error, _reason} = error -> error
            end
          end,
          session
        )

      send(client, {:model_list_result, ref, reply})
    end)
  end

  defp maybe_cache_model_list_reply(state, {:ok, %ModelListResponse{} = reply}) do
    %{state | model_list_cache: reply}
  end

  defp maybe_cache_model_list_reply(state, _reply), do: state

  defp maybe_reject_unknown_request(payload, method, %{session: session, strict_protocol: true}) do
    case Map.get(payload, "id") do
      request_id when not is_nil(request_id) ->
        spawn_request_handler(session, request_id, fn ->
          {:error, %{"code" => -32_602, "message" => "Unsupported app-server request method: #{method}"}}
        end)

      _other ->
        :ok
    end
  end

  defp maybe_reject_unknown_request(_payload, _method, _state), do: :ok

  defp maybe_handle_request(message, %{request_handler: handler, session: session}) when is_function(handler, 1) do
    case Message.request_id(message) do
      nil ->
        :ok

      request_id ->
        client = self()

        spawn_request_handler(
          session,
          request_id,
          fn -> normalize_request_handler_reply(handler.(message)) end,
          fn -> send(client, {:request_handler_replied, request_id}) end
        )
    end
  end

  defp maybe_handle_request(_message, _state), do: :ok

  defp spawn_request_handler(session, request_id, fun, on_reply \\ fn -> :ok end) do
    :ok =
      start_async_child(fn ->
        reply =
          try do
            fun.()
          rescue
            error ->
              {:error,
               %{
                 "code" => -32_604,
                 "message" => "request handler failed: #{Exception.message(error)}"
               }}
          catch
            :exit, reason ->
              {:error, %{"code" => -32_603, "message" => "request handler exited: #{inspect(reason)}"}}
          end

        if Session.respond(session, request_id, reply, @default_timeout) == :ok do
          on_reply.()
        end
      end)

    :ok
  end

  defp normalize_request_handler_reply({:ok, result}), do: normalize_request_handler_result(result)

  defp normalize_request_handler_reply({:error, _reason} = reply), do: reply

  defp normalize_request_handler_reply(reply), do: normalize_request_handler_result(reply)

  defp normalize_request_handler_result(result) do
    if Message.supported_reply_payload?(result) do
      {:ok, result}
    else
      reason = {:unsupported_request_reply_payload, result}
      {:error, request_handler_payload_error(reason)}
    end
  end

  defp request_handler_payload_error(reason) do
    %{
      "code" => -32_605,
      "message" => "unsupported request handler reply payload",
      "data" => %{"reason" => inspect(reason)}
    }
  end

  defp run_deferred(fun, session) do
    fun.(session)
  rescue
    error ->
      {:error, {:defer_failed, {error.__struct__, Exception.message(error)}}}
  catch
    :exit, reason ->
      {:error, {:session_request_failed, reason}}

    kind, reason ->
      {:error, {:defer_failed, {kind, reason}}}
  end

  defp start_async_child(fun) do
    case Task.Supervisor.start_child(CodexEx.TaskSupervisor, fun) do
      {:ok, _pid} -> :ok
      {:error, reason} -> {:error, {:defer_failed, reason}}
    end
  end

  defp safe_client_call(client, message, timeout) do
    GenServer.call(client, message, timeout)
  catch
    :exit, reason ->
      {:error, {:client_call_failed, reason}}
  end

  defp call_timeout_for(timeout) when is_integer(timeout) and timeout >= 0 do
    timeout + @client_call_grace_ms
  end

  defp call_timeout_for(:infinity), do: @turn_timeout + @client_call_grace_ms

  @spec client_server(t()) :: GenServer.server()
  defp client_server(client) when is_pid(client), do: client
  defp client_server(client) when is_atom(client), do: client
  defp client_server({name, node} = client) when is_atom(name) and is_atom(node), do: client
  defp client_server({:global, _name} = client), do: client
  defp client_server({:via, module, _name} = client) when is_atom(module), do: client
end
