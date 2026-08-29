defmodule CodexEx.AppServer.Protocol.Generated.Shared.ClientRequest do
  @moduledoc false

  alias CodexEx.AppServer.Protocol.Codec

  defstruct [:id, :method, :params]

  @method_specs %{
    "account/login/cancel" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.CancelLoginAccountParams
    },
    "account/login/start" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.LoginAccountParams
    },
    "account/logout" => %{params_module: nil},
    "account/rateLimitResetCredit/consume" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ConsumeAccountRateLimitResetCreditParams
    },
    "account/rateLimits/read" => %{params_module: nil},
    "account/read" => %{params_module: CodexEx.AppServer.Protocol.Generated.V2.GetAccountParams},
    "account/sendAddCreditsNudgeEmail" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.SendAddCreditsNudgeEmailParams
    },
    "account/usage/read" => %{params_module: nil},
    "account/workspaceMessages/read" => %{params_module: nil},
    "app/installed" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.AppsInstalledParams
    },
    "app/list" => %{params_module: CodexEx.AppServer.Protocol.Generated.V2.AppsListParams},
    "app/read" => %{params_module: CodexEx.AppServer.Protocol.Generated.V2.AppsReadParams},
    "collaborationMode/list" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.CollaborationModeListParams
    },
    "command/exec" => %{params_module: CodexEx.AppServer.Protocol.Generated.V2.CommandExecParams},
    "command/exec/resize" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.CommandExecResizeParams
    },
    "command/exec/terminate" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.CommandExecTerminateParams
    },
    "command/exec/write" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.CommandExecWriteParams
    },
    "config/batchWrite" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ConfigBatchWriteParams
    },
    "config/mcpServer/reload" => %{params_module: nil},
    "config/read" => %{params_module: CodexEx.AppServer.Protocol.Generated.V2.ConfigReadParams},
    "config/value/write" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ConfigValueWriteParams
    },
    "configRequirements/read" => %{params_module: nil},
    "environment/add" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.EnvironmentAddParams
    },
    "environment/info" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.EnvironmentInfoParams
    },
    "environment/status" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.EnvironmentStatusParams
    },
    "experimentalFeature/enablement/set" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ExperimentalFeatureEnablementSetParams
    },
    "experimentalFeature/list" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ExperimentalFeatureListParams
    },
    "externalAgentConfig/detect" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ExternalAgentConfigDetectParams
    },
    "externalAgentConfig/import" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ExternalAgentConfigImportParams
    },
    "externalAgentConfig/import/readHistories" => %{params_module: nil},
    "externalAgentConfig/import/recordHistory" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ExternalAgentConfigImportHistoryRecordParams
    },
    "feedback/upload" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.FeedbackUploadParams
    },
    "fs/copy" => %{params_module: CodexEx.AppServer.Protocol.Generated.V2.FsCopyParams},
    "fs/createDirectory" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.FsCreateDirectoryParams
    },
    "fs/getMetadata" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.FsGetMetadataParams
    },
    "fs/readDirectory" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.FsReadDirectoryParams
    },
    "fs/readFile" => %{params_module: CodexEx.AppServer.Protocol.Generated.V2.FsReadFileParams},
    "fs/remove" => %{params_module: CodexEx.AppServer.Protocol.Generated.V2.FsRemoveParams},
    "fs/unwatch" => %{params_module: CodexEx.AppServer.Protocol.Generated.V2.FsUnwatchParams},
    "fs/watch" => %{params_module: CodexEx.AppServer.Protocol.Generated.V2.FsWatchParams},
    "fs/writeFile" => %{params_module: CodexEx.AppServer.Protocol.Generated.V2.FsWriteFileParams},
    "fuzzyFileSearch" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.Shared.FuzzyFileSearchParams
    },
    "fuzzyFileSearch/sessionStart" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.Shared.FuzzyFileSearchSessionStartParams
    },
    "fuzzyFileSearch/sessionStop" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.Shared.FuzzyFileSearchSessionStopParams
    },
    "fuzzyFileSearch/sessionUpdate" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.Shared.FuzzyFileSearchSessionUpdateParams
    },
    "hooks/list" => %{params_module: CodexEx.AppServer.Protocol.Generated.V2.HooksListParams},
    "initialize" => %{params_module: CodexEx.AppServer.Protocol.Generated.V1.InitializeParams},
    "marketplace/add" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.MarketplaceAddParams
    },
    "marketplace/remove" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.MarketplaceRemoveParams
    },
    "marketplace/upgrade" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.MarketplaceUpgradeParams
    },
    "mcpServer/oauth/login" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.McpServerOauthLoginParams
    },
    "mcpServer/resource/read" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.McpResourceReadParams
    },
    "mcpServer/tool/call" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.McpServerToolCallParams
    },
    "mcpServerStatus/list" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ListMcpServerStatusParams
    },
    "memory/reset" => %{params_module: nil},
    "mock/experimentalMethod" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.MockExperimentalMethodParams
    },
    "model/list" => %{params_module: CodexEx.AppServer.Protocol.Generated.V2.ModelListParams},
    "modelProvider/capabilities/read" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ModelProviderCapabilitiesReadParams
    },
    "permissionProfile/list" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.PermissionProfileListParams
    },
    "plugin/install" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.PluginInstallParams
    },
    "plugin/installed" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.PluginInstalledParams
    },
    "plugin/list" => %{params_module: CodexEx.AppServer.Protocol.Generated.V2.PluginListParams},
    "plugin/read" => %{params_module: CodexEx.AppServer.Protocol.Generated.V2.PluginReadParams},
    "plugin/search" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.PluginSearchParams
    },
    "plugin/share/checkout" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.PluginShareCheckoutParams
    },
    "plugin/share/delete" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.PluginShareDeleteParams
    },
    "plugin/share/list" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.PluginShareListParams
    },
    "plugin/share/save" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.PluginShareSaveParams
    },
    "plugin/share/updateTargets" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.PluginShareUpdateTargetsParams
    },
    "plugin/skill/read" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.PluginSkillReadParams
    },
    "plugin/uninstall" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.PluginUninstallParams
    },
    "process/kill" => %{params_module: CodexEx.AppServer.Protocol.Generated.V2.ProcessKillParams},
    "process/resizePty" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ProcessResizePtyParams
    },
    "process/spawn" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ProcessSpawnParams
    },
    "process/writeStdin" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ProcessWriteStdinParams
    },
    "remoteControl/client/list" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.RemoteControlClientsListParams
    },
    "remoteControl/client/revoke" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.RemoteControlClientsRevokeParams
    },
    "remoteControl/disable" => %{params_module: nil},
    "remoteControl/enable" => %{params_module: nil},
    "remoteControl/pairing/start" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.RemoteControlPairingStartParams
    },
    "remoteControl/pairing/status" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.RemoteControlPairingStatusParams
    },
    "remoteControl/status/read" => %{params_module: nil},
    "review/start" => %{params_module: CodexEx.AppServer.Protocol.Generated.V2.ReviewStartParams},
    "server/diagnostics" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ServerDiagnosticsParams
    },
    "skills/config/write" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.SkillsConfigWriteParams
    },
    "skills/extraRoots/set" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.SkillsExtraRootsSetParams
    },
    "skills/list" => %{params_module: CodexEx.AppServer.Protocol.Generated.V2.SkillsListParams},
    "thread/approveGuardianDeniedAction" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadApproveGuardianDeniedActionParams
    },
    "thread/archive" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadArchiveParams
    },
    "thread/backgroundTerminals/clean" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadBackgroundTerminalsCleanParams
    },
    "thread/backgroundTerminals/list" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadBackgroundTerminalsListParams
    },
    "thread/backgroundTerminals/terminate" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadBackgroundTerminalsTerminateParams
    },
    "thread/compact/start" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadCompactStartParams
    },
    "thread/decrement_elicitation" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadDecrementElicitationParams
    },
    "thread/delete" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadDeleteParams
    },
    "thread/fork" => %{params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadForkParams},
    "thread/goal/clear" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadGoalClearParams
    },
    "thread/goal/get" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadGoalGetParams
    },
    "thread/goal/set" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadGoalSetParams
    },
    "thread/increment_elicitation" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadIncrementElicitationParams
    },
    "thread/inject_items" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadInjectItemsParams
    },
    "thread/items/list" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadItemsListParams
    },
    "thread/list" => %{params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadListParams},
    "thread/loaded/list" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadLoadedListParams
    },
    "thread/memoryMode/set" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadMemoryModeSetParams
    },
    "thread/metadata/update" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadMetadataUpdateParams
    },
    "thread/name/set" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadSetNameParams
    },
    "thread/queue/add" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadQueueAddParams
    },
    "thread/queue/delete" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadQueueDeleteParams
    },
    "thread/queue/list" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadQueueListParams
    },
    "thread/queue/reorder" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadQueueReorderParams
    },
    "thread/queue/start" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadQueueStartParams
    },
    "thread/queue/update" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadQueueUpdateParams
    },
    "thread/read" => %{params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadReadParams},
    "thread/realtime/appendAudio" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadRealtimeAppendAudioParams
    },
    "thread/realtime/appendSpeech" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadRealtimeAppendSpeechParams
    },
    "thread/realtime/appendText" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadRealtimeAppendTextParams
    },
    "thread/realtime/listVoices" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadRealtimeListVoicesParams
    },
    "thread/realtime/start" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadRealtimeStartParams
    },
    "thread/realtime/stop" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadRealtimeStopParams
    },
    "thread/resume" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadResumeParams
    },
    "thread/revert" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadRevertParams
    },
    "thread/rollback" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadRollbackParams
    },
    "thread/search" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadSearchParams
    },
    "thread/searchOccurrences" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadSearchOccurrencesParams
    },
    "thread/section/move" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadSectionMoveParams
    },
    "thread/settings/update" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadSettingsUpdateParams
    },
    "thread/shellCommand" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadShellCommandParams
    },
    "thread/start" => %{params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadStartParams},
    "thread/turns/list" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadTurnsListParams
    },
    "thread/unarchive" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadUnarchiveParams
    },
    "thread/unsubscribe" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadUnsubscribeParams
    },
    "threadSection/create" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadSectionCreateParams
    },
    "threadSection/delete" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadSectionDeleteParams
    },
    "threadSection/list" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadSectionListParams
    },
    "threadSection/update" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.ThreadSectionUpdateParams
    },
    "turn/interrupt" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.TurnInterruptParams
    },
    "turn/start" => %{params_module: CodexEx.AppServer.Protocol.Generated.V2.TurnStartParams},
    "turn/steer" => %{params_module: CodexEx.AppServer.Protocol.Generated.V2.TurnSteerParams},
    "windowsSandbox/readiness" => %{params_module: nil},
    "windowsSandbox/setupStart" => %{
      params_module: CodexEx.AppServer.Protocol.Generated.V2.WindowsSandboxSetupStartParams
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
