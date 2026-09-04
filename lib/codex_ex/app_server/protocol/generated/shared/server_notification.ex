defmodule CodexEx.AppServer.Protocol.Generated.Shared.ServerNotification do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec
  alias CodexEx.AppServer.Protocol.Generated.V2.AuthRecoveryNotification
  alias CodexEx.AppServer.Protocol.Generated.V2.EnvironmentConnectionNotification

  defstruct [:id, :method, :params]

  @method_specs %{
    "account/login/completed" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.AccountLoginCompletedNotification
    },
    "account/rateLimits/updated" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.AccountRateLimitsUpdatedNotification
    },
    "account/updated" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.AccountUpdatedNotification
    },
    "app/list/updated" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.AppListUpdatedNotification
    },
    "autoApprovalReview/strictReviewRequired" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.StrictReviewRequiredNotification
    },
    "command/exec/outputDelta" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.CommandExecOutputDeltaNotification
    },
    "configWarning" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ConfigWarningNotification
    },
    "deprecationNotice" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.DeprecationNoticeNotification
    },
    "error" => %{params_module: CodexEx.AppServer.Protocol.Generated.V2.ErrorNotification},
    "externalAgentConfig/import/completed" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ExternalAgentConfigImportCompletedNotification
    },
    "externalAgentConfig/import/progress" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ExternalAgentConfigImportProgressNotification
    },
    "fs/changed" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.FsChangedNotification
    },
    "fuzzyFileSearch/sessionCompleted" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.Shared.FuzzyFileSearchSessionCompletedNotification
    },
    "fuzzyFileSearch/sessionUpdated" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.Shared.FuzzyFileSearchSessionUpdatedNotification
    },
    "guardianWarning" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.GuardianWarningNotification
    },
    "hook/completed" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.HookCompletedNotification
    },
    "hook/started" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.HookStartedNotification
    },
    "item/agentMessage/delta" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.AgentMessageDeltaNotification
    },
    "item/autoApprovalReview/completed" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ItemGuardianApprovalReviewCompletedNotification
    },
    "item/autoApprovalReview/started" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ItemGuardianApprovalReviewStartedNotification
    },
    "item/commandExecution/outputDelta" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.CommandExecutionOutputDeltaNotification
    },
    "item/commandExecution/terminalInteraction" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.TerminalInteractionNotification
    },
    "item/completed" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ItemCompletedNotification
    },
    "item/fileChange/outputDelta" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.FileChangeOutputDeltaNotification
    },
    "item/fileChange/patchUpdated" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.FileChangePatchUpdatedNotification
    },
    "item/mcpToolCall/progress" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.McpToolCallProgressNotification
    },
    "item/plan/delta" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.PlanDeltaNotification
    },
    "item/reasoning/summaryPartAdded" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ReasoningSummaryPartAddedNotification
    },
    "item/reasoning/summaryTextDelta" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ReasoningSummaryTextDeltaNotification
    },
    "item/reasoning/textDelta" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ReasoningTextDeltaNotification
    },
    "item/started" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ItemStartedNotification
    },
    "mcpServer/event/stream/notification" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.McpServerEventStreamNotification
    },
    "mcpServer/oauthLogin/completed" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.McpServerOauthLoginCompletedNotification
    },
    "mcpServer/startupStatus/updated" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.McpServerStatusUpdatedNotification
    },
    "model/rerouted" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ModelReroutedNotification
    },
    "model/safetyBuffering/updated" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ModelSafetyBufferingUpdatedNotification
    },
    "model/verification" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ModelVerificationNotification
    },
    "modelProvider/authRecoveryCompleted" => %{
      params_module: AuthRecoveryNotification
    },
    "modelProvider/authRecoveryStarted" => %{
      params_module: AuthRecoveryNotification
    },
    "process/exited" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ProcessExitedNotification
    },
    "process/outputDelta" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ProcessOutputDeltaNotification
    },
    "project/changed" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ProjectChangedNotification
    },
    "remoteControl/status/changed" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.RemoteControlStatusChangedNotification
    },
    "serverRequest/resolved" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ServerRequestResolvedNotification
    },
    "skills/changed" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.SkillsChangedNotification
    },
    "thread/archived" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadArchivedNotification
    },
    "thread/closed" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadClosedNotification
    },
    "thread/compacted" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ContextCompactedNotification
    },
    "thread/deleted" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadDeletedNotification
    },
    "thread/environment/connected" => %{
      params_module: EnvironmentConnectionNotification
    },
    "thread/environment/disconnected" => %{
      params_module: EnvironmentConnectionNotification
    },
    "thread/goal/cleared" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadGoalClearedNotification
    },
    "thread/goal/updated" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadGoalUpdatedNotification
    },
    "thread/name/updated" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadNameUpdatedNotification
    },
    "thread/project/updated" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadProjectUpdatedNotification
    },
    "thread/queue/changed" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadQueueChangedNotification
    },
    "thread/realtime/closed" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadRealtimeClosedNotification
    },
    "thread/realtime/error" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadRealtimeErrorNotification
    },
    "thread/realtime/item/completed" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadRealtimeItemCompletedNotification
    },
    "thread/realtime/item/started" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadRealtimeItemStartedNotification
    },
    "thread/realtime/item/transcript/delta" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadRealtimeItemTranscriptDeltaNotification
    },
    "thread/realtime/itemAdded" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadRealtimeItemAddedNotification
    },
    "thread/realtime/outputAudio/delta" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadRealtimeOutputAudioDeltaNotification
    },
    "thread/realtime/sdp" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadRealtimeSdpNotification
    },
    "thread/realtime/started" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadRealtimeStartedNotification
    },
    "thread/realtime/transcript/delta" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadRealtimeTranscriptDeltaNotification
    },
    "thread/realtime/transcript/done" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadRealtimeTranscriptDoneNotification
    },
    "thread/reverted" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadRevertedNotification
    },
    "thread/settings/updated" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadSettingsUpdatedNotification
    },
    "thread/started" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadStartedNotification
    },
    "thread/status/changed" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadStatusChangedNotification
    },
    "thread/tokenUsage/updated" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadTokenUsageUpdatedNotification
    },
    "thread/unarchived" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadUnarchivedNotification
    },
    "turn/completed" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.TurnCompletedNotification
    },
    "turn/diff/updated" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.TurnDiffUpdatedNotification
    },
    "turn/moderationMetadata" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.TurnModerationMetadataNotification
    },
    "turn/plan/updated" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.TurnPlanUpdatedNotification
    },
    "turn/started" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.TurnStartedNotification
    },
    "warning" => %{params_module: CodexEx.AppServer.Protocol.Generated.V2.WarningNotification},
    "windows/worldWritableWarning" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.WindowsWorldWritableWarningNotification
    },
    "windowsSandbox/setupCompleted" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.WindowsSandboxSetupCompletedNotification
    }
  }

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

  defp maybe_put_id(payload, nil), do: payload
  defp maybe_put_id(payload, id), do: Map.put(payload, "id", id)
end
