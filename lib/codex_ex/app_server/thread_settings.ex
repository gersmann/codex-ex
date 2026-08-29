defmodule CodexEx.AppServer.ThreadSettings do
  @moduledoc """
  Effective Codex settings observed for a loaded thread.

  App-created threads retain the private instruction seed needed to replay the
  settings exactly. Legacy resumes still expose their effective settings to the
  runtime, but are not replayable into a fork.
  """

  alias CodexEx.AppServer.Protocol.Generated.V2.ThreadSettingsUpdatedNotification
  alias CodexEx.AppServer.ProtocolValue

  defstruct [
    :active_permission_profile_id,
    :approval_policy,
    :approvals_reviewer,
    :cwd,
    :developer_instructions,
    :model,
    :model_provider,
    :personality,
    :replayable?,
    :reasoning_effort,
    :reasoning_summary,
    :runtime_workspace_roots,
    :sandbox_policy,
    :service_tier
  ]

  @type approval_policy :: binary() | map()
  @type t :: %__MODULE__{
          active_permission_profile_id: binary() | nil,
          approval_policy: approval_policy(),
          approvals_reviewer: binary(),
          cwd: binary(),
          developer_instructions: binary() | nil,
          model: binary(),
          model_provider: binary(),
          personality: binary() | nil,
          replayable?: boolean(),
          reasoning_effort: binary() | nil,
          reasoning_summary: binary() | nil,
          runtime_workspace_roots: [term()],
          sandbox_policy: map(),
          service_tier: binary() | nil
        }

  @type instruction_seed :: %{
          required(:developer_instructions) => binary() | nil,
          required(:personality) => binary() | nil,
          required(:reasoning_summary) => binary() | nil
        }
  @type instruction_seed_input :: %{
          required(:developer_instructions) => binary() | nil,
          required(:personality) => binary() | nil,
          required(:reasoning_summary) => binary() | nil,
          optional(term()) => term()
        }

  @doc "Builds effective settings and records whether their instruction seed is replayable."
  @spec from_protocol(map(), instruction_seed_input() | nil) :: t() | nil
  def from_protocol(source, nil) when is_map(source) do
    build_from_protocol(source, nil, nil, nil, false)
  end

  def from_protocol(source, %{
        developer_instructions: developer_instructions,
        personality: personality,
        reasoning_summary: reasoning_summary
      })
      when is_map(source) and (is_binary(developer_instructions) or is_nil(developer_instructions)) and
             (is_binary(personality) or is_nil(personality)) and
             (is_binary(reasoning_summary) or is_nil(reasoning_summary)) do
    build_from_protocol(
      source,
      developer_instructions,
      personality,
      reasoning_summary,
      true
    )
  end

  defp build_from_protocol(source, developer_instructions, personality, reasoning_summary, replayable?) do
    case ProtocolValue.fetch(source, :service_tier) do
      {:ok, service_tier} ->
        settings = %__MODULE__{
          active_permission_profile_id: active_permission_profile_id(source),
          approval_policy: ProtocolValue.get(source, :approval_policy),
          approvals_reviewer: ProtocolValue.get(source, :approvals_reviewer),
          cwd: ProtocolValue.get(source, :cwd),
          developer_instructions: developer_instructions,
          model: ProtocolValue.get(source, :model),
          model_provider: ProtocolValue.get(source, :model_provider),
          personality: personality,
          replayable?: replayable?,
          reasoning_effort: optional_binary(ProtocolValue.get(source, :reasoning_effort)),
          reasoning_summary: reasoning_summary,
          runtime_workspace_roots: ProtocolValue.get(source, :runtime_workspace_roots),
          sandbox_policy: ProtocolValue.get(source, :sandbox),
          service_tier: optional_binary(service_tier)
        }

        validated_settings(settings)

      :error ->
        nil
    end
  end

  @doc "Returns the private persisted seed needed to reconstruct root instructions on resume."
  @spec persisted_seed(t() | nil) :: map() | nil
  def persisted_seed(%__MODULE__{replayable?: true} = settings),
    do: %{
      "developerInstructions" => settings.developer_instructions,
      "personality" => settings.personality,
      "reasoningSummary" => settings.reasoning_summary
    }

  def persisted_seed(%__MODULE__{}), do: nil
  def persisted_seed(nil), do: nil

  @doc "Decodes the private persisted seed without guessing at missing values."
  @spec decode_persisted_seed(term()) ::
          {:ok, instruction_seed()} | {:error, :invalid_thread_settings_seed}
  def decode_persisted_seed(%{
        "developerInstructions" => developer_instructions,
        "personality" => personality,
        "reasoningSummary" => reasoning_summary
      })
      when (is_binary(developer_instructions) or is_nil(developer_instructions)) and
             (is_binary(personality) or is_nil(personality)) and
             (is_binary(reasoning_summary) or is_nil(reasoning_summary)) do
    {:ok,
     %{
       developer_instructions: developer_instructions,
       personality: personality,
       reasoning_summary: reasoning_summary
     }}
  end

  def decode_persisted_seed(_seed), do: {:error, :invalid_thread_settings_seed}

  @doc "Applies a persisted source seed to a new thread/fork request."
  @spec put_persisted_seed(map(), map() | nil) ::
          {:ok, map()} | {:error, :invalid_thread_settings_seed}
  def put_persisted_seed(params, nil) when is_map(params), do: {:ok, params}

  def put_persisted_seed(params, seed) when is_map(params) and is_map(seed) do
    with {:ok, decoded} <- decode_persisted_seed(seed),
         {:ok, config} <- seed_config(Map.get(params, "config"), decoded) do
      {:ok,
       params
       |> Map.put("developerInstructions", decoded.developer_instructions)
       |> Map.put("config", config)}
    end
  end

  @doc "Applies the complete sticky settings notification to an existing snapshot."
  @spec apply_notification(t(), struct()) ::
          {:ok, t()} | {:error, :invalid_thread_settings}
  def apply_notification(%__MODULE__{} = current, %ThreadSettingsUpdatedNotification.ThreadSettings{} = update) do
    settings = %{
      current
      | active_permission_profile_id: active_permission_profile_id(update),
        approval_policy: update.approval_policy,
        approvals_reviewer: update.approvals_reviewer,
        cwd: update.cwd,
        model: update.model,
        model_provider: update.model_provider,
        personality: optional_binary(update.personality),
        reasoning_effort: optional_binary(update.effort),
        reasoning_summary: optional_binary(update.summary),
        sandbox_policy: update.sandbox_policy,
        service_tier: optional_binary(update.service_tier)
    }

    case validated_settings(settings) do
      %__MODULE__{} = settings -> {:ok, settings}
      nil -> {:error, :invalid_thread_settings}
    end
  end

  @doc "Returns exact thread/fork overrides with side-chat developer constraints appended."
  @spec side_fork_overrides(t(), binary()) :: {:ok, map()} | {:error, :settings_unavailable}
  def side_fork_overrides(%__MODULE__{replayable?: true} = settings, side_instructions)
      when is_binary(side_instructions) and side_instructions != "" do
    with {:ok, permission_overrides, permission_config} <- fork_permission_settings(settings) do
      config =
        %{}
        |> put_optional("model_reasoning_effort", settings.reasoning_effort)
        |> put_optional("model_reasoning_summary", settings.reasoning_summary)
        |> put_optional("personality", settings.personality)
        |> Map.merge(permission_config)

      overrides =
        Map.merge(
          %{
            "approvalPolicy" => settings.approval_policy,
            "approvalsReviewer" => settings.approvals_reviewer,
            "cwd" => settings.cwd,
            "developerInstructions" => append_instructions(settings.developer_instructions, side_instructions),
            "ephemeral" => true,
            "model" => settings.model,
            "modelProvider" => settings.model_provider,
            "runtimeWorkspaceRoots" => settings.runtime_workspace_roots,
            "serviceTier" => settings.service_tier
          },
          permission_overrides
        )

      {:ok, if(map_size(config) == 0, do: overrides, else: Map.put(overrides, "config", config))}
    end
  end

  def side_fork_overrides(%__MODULE__{}, _side_instructions), do: {:error, :settings_unavailable}

  defp validated_settings(%__MODULE__{} = settings) do
    with {:ok, profile_id} <- validate_optional_binary(settings.active_permission_profile_id),
         {:ok, approval_policy} <- validate_approval_policy(settings.approval_policy),
         {:ok, approvals_reviewer} <- validate_required_binary(settings.approvals_reviewer),
         {:ok, cwd} <- validate_required_binary(settings.cwd),
         {:ok, developer_instructions} <-
           validate_optional_binary(settings.developer_instructions),
         {:ok, model} <- validate_required_binary(settings.model),
         {:ok, model_provider} <- validate_required_binary(settings.model_provider),
         {:ok, personality} <- validate_optional_binary(settings.personality),
         {:ok, replayable?} <- validate_boolean(settings.replayable?),
         {:ok, reasoning_effort} <- validate_optional_binary(settings.reasoning_effort),
         {:ok, reasoning_summary} <- validate_optional_binary(settings.reasoning_summary),
         {:ok, runtime_workspace_roots} <-
           validate_workspace_roots(settings.runtime_workspace_roots),
         {:ok, sandbox_policy} <- validate_sandbox_policy(settings.sandbox_policy),
         {:ok, service_tier} <- validate_optional_binary(settings.service_tier) do
      %__MODULE__{
        active_permission_profile_id: profile_id,
        approval_policy: approval_policy,
        approvals_reviewer: approvals_reviewer,
        cwd: cwd,
        developer_instructions: developer_instructions,
        model: model,
        model_provider: model_provider,
        personality: personality,
        replayable?: replayable?,
        reasoning_effort: reasoning_effort,
        reasoning_summary: reasoning_summary,
        runtime_workspace_roots: runtime_workspace_roots,
        sandbox_policy: sandbox_policy,
        service_tier: service_tier
      }
    else
      :error -> nil
    end
  end

  defp validate_required_binary(value) when is_binary(value) and value != "", do: {:ok, value}
  defp validate_required_binary(_value), do: :error

  defp validate_optional_binary(nil), do: {:ok, nil}
  defp validate_optional_binary(value), do: validate_required_binary(value)

  defp validate_approval_policy(value) when is_binary(value) or is_map(value), do: {:ok, value}
  defp validate_approval_policy(_value), do: :error

  defp validate_boolean(value) when is_boolean(value), do: {:ok, value}
  defp validate_boolean(_value), do: :error

  defp validate_workspace_roots(value) when is_list(value), do: {:ok, Enum.to_list(value)}
  defp validate_workspace_roots(_value), do: :error

  defp validate_sandbox_policy(value) when is_map(value) do
    case ProtocolValue.to_json_value(value) do
      {:ok, policy} when is_map(policy) -> {:ok, policy}
      _other -> :error
    end
  end

  defp validate_sandbox_policy(_value), do: :error

  defp fork_permission_settings(%__MODULE__{active_permission_profile_id: profile_id})
       when is_binary(profile_id) and profile_id != "", do: {:ok, %{"permissions" => profile_id}, %{}}

  defp fork_permission_settings(%__MODULE__{sandbox_policy: sandbox_policy}) do
    legacy_sandbox_settings(sandbox_policy)
  end

  defp legacy_sandbox_settings(%{"type" => "dangerFullAccess"}), do: {:ok, %{"sandbox" => "danger-full-access"}, %{}}

  defp legacy_sandbox_settings(%{"networkAccess" => false, "type" => "readOnly"}),
    do: {:ok, %{"sandbox" => "read-only"}, %{}}

  defp legacy_sandbox_settings(%{
         "excludeSlashTmp" => exclude_slash_tmp,
         "excludeTmpdirEnvVar" => exclude_tmpdir_env_var,
         "networkAccess" => network_access,
         "type" => "workspaceWrite",
         "writableRoots" => writable_roots
       })
       when is_boolean(exclude_slash_tmp) and is_boolean(exclude_tmpdir_env_var) and is_boolean(network_access) and
              is_list(writable_roots) do
    if Enum.all?(writable_roots, &(is_binary(&1) and &1 != "")) do
      {:ok, %{"sandbox" => "workspace-write"},
       %{
         "sandbox_workspace_write.exclude_slash_tmp" => exclude_slash_tmp,
         "sandbox_workspace_write.exclude_tmpdir_env_var" => exclude_tmpdir_env_var,
         "sandbox_workspace_write.network_access" => network_access,
         "sandbox_workspace_write.writable_roots" => writable_roots
       }}
    else
      {:error, :settings_unavailable}
    end
  end

  defp legacy_sandbox_settings(_sandbox_policy), do: {:error, :settings_unavailable}

  defp active_permission_profile_id(source) do
    case ProtocolValue.get(source, :active_permission_profile) do
      profile when is_map(profile) -> optional_binary(ProtocolValue.get(profile, :id))
      _other -> nil
    end
  end

  defp optional_binary(value) when is_binary(value) and value != "", do: value
  defp optional_binary(_value), do: nil

  defp put_optional(map, _key, nil), do: map
  defp put_optional(map, key, value), do: Map.put(map, key, value)

  defp append_instructions(nil, side_instructions), do: side_instructions

  defp append_instructions(developer_instructions, side_instructions),
    do: developer_instructions <> "\n\n" <> side_instructions

  defp seed_config(nil, seed), do: seed_config(%{}, seed)

  defp seed_config(config, seed) when is_map(config) do
    {:ok,
     config
     |> put_optional("model_reasoning_summary", seed.reasoning_summary)
     |> put_optional("personality", seed.personality)}
  end

  defp seed_config(_config, _seed), do: {:error, :invalid_thread_settings_seed}
end
