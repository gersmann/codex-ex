# codex_ex

Elixir client for the Codex app-server JSON-RPC 2.0 protocol. Owns the client
GenServer, session framing, transport abstraction, turn streaming, client
pooling, and a fully code-generated protocol binding.

## Installation

```elixir
def deps do
  [
    {:codex_ex, "~> 0.3.0"}
  ]
end
```

Requires a `codex` executable on `$PATH` for the default stdio transport
(or pass `executable:` / use the websocket transport).

## Usage

Get a pooled client and run a turn to completion:

```elixir
alias CodexEx.AppServer.{Client, ClientManager, TurnStream}

# Pooled: callers with the same connection options share one client
# (and one underlying `codex app-server` OS process).
{:ok, client} = ClientManager.get_client(transport: :stdio)

# Start a thread and run a prompt to completion.
{:ok, thread} = Client.start_thread(client, %{"cwd" => "/path/to/workspace"})
input = [%{"type" => "text", "text" => "Summarize the TODOs in this repo."}]

{:ok, stream} =
  TurnStream.start_request(client, thread.id, fn ->
    Client.start_turn(client, thread.id, input)
  end)

{:ok, stream} = TurnStream.wait(stream)
:ok = TurnStream.ensure_success(stream)
stream.final_text
stream.items
stream.usage
```

For structured output, pass an `outputSchema` turn option and decode the final
stream value:

```elixir
schema =
  %{
    "type" => "object",
    "properties" => %{"languages" => %{"type" => "array", "items" => %{"type" => "string"}}},
    "required" => ["languages"]
  }

{:ok, stream} =
  TurnStream.start_request(client, thread.id, fn ->
    Client.start_turn(
      client,
      thread.id,
      [%{"type" => "text", "text" => "List the languages used in this repo."}],
      %{"outputSchema" => schema}
    )
  end)

{:ok, stream} = TurnStream.wait(stream)
:ok = TurnStream.ensure_success(stream)
{:ok, %{"languages" => _}} = TurnStream.final_json(stream)
```

To observe streamed events (deltas, item updates, token usage) while a turn
runs, subscribe before starting it — every parsed server event arrives as
`{:codex_app_server_event, message}`:

```elixir
:ok = Client.subscribe(client)

{:ok, _stream} =
  TurnStream.start_request(client, thread.id, fn ->
    Client.start_turn(client, thread.id, [%{"type" => "text", "text" => "Go"}])
  end)

receive do
  {:codex_app_server_event, message} ->
    CodexEx.AppServer.Message.extract_text_delta(message)
end
```

Server-initiated requests (tool approvals, user-input elicitation) are
broadcast to subscribers. Read their request id with `Message.request_id/1`
and answer with `Client.reply_request/4`:

```elixir
request =
  receive do
    {:codex_app_server_event, message} -> message
  end

request_id = CodexEx.AppServer.Message.request_id(request)
:ok = Client.reply_request(client, request_id, {:ok, %{"decision" => "approved"}})
```

Resume an existing thread by id with `Client.resume_thread(client, thread_id)`;
fork, archive, goals, model/skill listing, and fuzzy file search are on `Client`.
`Thread` provides snapshot refresh and paginated turn reads.

## Host integration

The package runs its own supervision tree (`CodexEx.Application`): a
`Task.Supervisor` (`CodexEx.TaskSupervisor`), a `Registry`
(`CodexEx.ClientRegistry`), a `DynamicSupervisor` (`CodexEx.ClientSupervisor`),
and the `ClientManager` singleton.

Optional host configuration:

```elixir
config :codex_ex,
  # Phoenix.PubSub server for thread-activity broadcasts (nil disables them)
  pubsub: MyApp.PubSub
```

To publish threads already active on the local app server, add the observer to
your own supervision tree after the PubSub and anything its recovery hook needs:

```elixir
children = [
  {Phoenix.PubSub, name: MyApp.PubSub},
  # ...
  {CodexEx.ThreadActivityObserver,
   # optional, must return {:ok, term()} | {:error, term()}; errors are retried
   recover: {MyApp.SessionRecovery, :recover_pending_sessions, [[runtime_type: "local"]]}}
]
```

`CodexEx.ThreadActivityObserver.reconcile/0` re-publishes on demand.

Custom transports implement the `CodexEx.AppServer.Transport` behaviour and are
passed as the `:transport` option. Remote transports (sessions that outlive the
node) additionally implement the optional callbacks `remote_transport?/0`,
`reconcile_thread_activity/1`, `acknowledge/2`, `acknowledge_replay_gap/2`, and
`session_bootstrap/1`.

---

## Process Hierarchy

```
ClientRegistry (unique Registry, key = connection identity)
ClientManager (singleton; monitors registered Clients)
ClientSupervisor (DynamicSupervisor)
  └─ Client (one per unique connection key, :temporary)
       State: session pid, subscribers, pending requests
       │
       └─ Session (one per Client, linked)
            State: JSON-RPC framing, pending request map, buffer
            │
            └─ Transport (one per Session)
                 ├─ StdioTransport   — managed proxy when available, standalone fallback
                 ├─ WebSocketTransport — Mint HTTP + Mint.WebSocket (GenServer)
                 └─ any host-provided Transport module (e.g. a remote bridge)
```

Additionally, each `TurnStream.start_request/4` call spawns a `TurnStream`
GenServer (one per active turn) that collects streamed notifications until the
turn completes.

All Clients are started under `CodexEx.ClientSupervisor`
(a DynamicSupervisor) with `:temporary` restart — they do not restart on
crash. Each Client registers in `CodexEx.ClientRegistry` under its
connection key, so a `ClientManager` restart forgets nothing: it rebuilds its
monitors from the registry. Normal Client shutdown also stops its owned Session
and transport.

---

## Module Reference

### Core GenServers

#### `Client`

Central GenServer wrapping a single app-server connection. Exposes the
full domain API (threads, turns, goals, models, skills, fuzzy search)
and manages subscriber fan-out for streamed server events.

The client owns its `Session`, thread-scoped subscribers, pending server
requests, model-list cache, and replay-gap ownership.

**Timeouts:**
- Default RPC: 15 seconds
- Turn operations: 30 minutes
- Client call grace: 1 second (added to RPC timeout for GenServer.call)

**Deferred reply pattern:**
All domain calls (thread start/resume/read, turn run, goal ops) use the
same flow: the GenServer `handle_call` captures `from`, spawns a `Task`
under `CodexEx.TaskSupervisor`, that task issues the RPC
through `Session` and calls `GenServer.reply(from, result)`. This
prevents the Client GenServer from blocking on slow network calls.

**Key operations:**
- Thread lifecycle: `start_thread`, `resume_thread`, `read_thread`,
  `fork_thread`, `archive_thread`, `unarchive_thread`,
  `start_thread_compaction`, `revert_thread`
- Turn lifecycle: `start_turn`, `start_turn_request`, `steer_turn`,
  `interrupt_turn`
- Goals: `set_thread_goal`, `get_thread_goal`, `clear_thread_goal`
- Capabilities: `list_models`, `list_skills`, `list_threads`,
  `list_experimental_features`, `set_experimental_feature_enablement`
- Fuzzy file search: `start_fuzzy_file_search_session`,
  `update_fuzzy_file_search_session`, `stop_fuzzy_file_search_session`
- Subscription: `subscribe/1`, `unsubscribe/1` — subscribers receive
  `{:codex_app_server_event, Message.t()}` for every parsed server event

**Server-initiated request handling:**
When the server sends a request (tool approval, MCP elicitation), the Client
parses it via `Protocol.Parser` and broadcasts it to subscribers. A subscriber
answers with `Client.reply_request/4`, which sends the response through
`Session`.

#### `ClientManager`

Pools `Client` processes by connection identity through `CodexEx.ClientRegistry`.
The GenServer itself only monitors clients so a dead remote client triggers its
transport's `reconcile_thread_activity/1`.

The effective identity includes transport, launcher, workspace/runner,
initialize, and protocol options. Remote daemon transport ids intentionally
exclude local-only observer flags so deploys can reattach retained sessions.

`get_client/1` runs in the caller: it returns the registered client for the key
or starts one under `CodexEx.ClientSupervisor`; concurrent starts for one key
resolve to a single client through the unique registry name.

#### `Session`

GenServer implementing JSON-RPC 2.0 framing over a pluggable transport.

The session owns request ids, pending request timers, the partial-line buffer,
the transport handle, and ordered transport acknowledgement state.

**Protocol details:**
- Request IDs are incrementing integers starting at 1
- Outgoing payloads normalized through `ClientRequest.encode/1`
  (generated module)
- Line-based parsing: incoming data split on `\n`, partial lines buffered
- Per-request timeouts via `Process.send_after/3`, max 30 minutes
- On transport close: replies all pending requests with
  `{:error, {:transport_closed, reason}}`, then stops

**Transport selection (via `:transport` option):**
- `:stdio` → `StdioTransport`
- `:websocket` → `WebSocketTransport`
- `:mock` → `MockTransport`
- Any atom → used directly as the transport module

#### `TurnStream`

GenServer that collects streamed notifications for a single agent turn.
Started by `TurnStream.start_request/4`, it correlates items, text deltas, turn
events, and token usage into a coherent result.

**Public struct:**
```elixir
%TurnStream{
  final_text: binary() | nil,
  final_turn: Turn.t() | nil,
  initial_turn: Turn.t() | nil,
  items: [ThreadItem.t()],
  pid: pid(),
  text_deltas: [binary()],
  thread_id: binary(),
  turn_id: binary() | nil,
  usage: TokenUsage.t() | nil
}
```

**Race handling:**
Notifications may arrive before the RPC result returns the `turn_id`.
TurnStream buffers these as `pending_messages_rev` and replays them once
the turn ID is known from the RPC result.

**Completion semantics:**
A turn is only complete when BOTH conditions are met:
1. The RPC result has returned (`rpc_final_turn`)
2. A final turn event has arrived (`event_final_turn`)

`best_final_turn/1` prefers the RPC result over the event turn.

**Item merging:**
`AgentMessage` items merge by status rank comparison:
- `completed` / `failed` / `interrupted` = rank 3
- `inProgress` = rank 2
- everything else = rank 1

Higher-ranked status wins; text is replaced only when the new item
carries a non-nil text value.

**Text delta handling:**
Deltas are ignored after the RPC final turn arrives with a non-empty
`final_text`, preventing late-arriving deltas from corrupting the result.

**Default wait timeout:** 30 minutes.

---

### Transport Layer

#### `Transport` (behaviour)

Defines the contract for all transport implementations:

```elixir
@callback open(opts :: keyword()) :: {:ok, handle :: term()} | {:error, term()}
@callback send(handle :: term(), data :: binary()) :: :ok | {:error, term()}
@callback close(handle :: term()) :: :ok
@callback normalize_message(raw :: term(), handle :: term()) ::
            {:data, binary()}
            | {:data, binary(), non_neg_integer()}
            | {:closed, term()}
            | {:closed, term(), non_neg_integer()}
            | {:replay_gap, map()}
            | :ignore
```

The `Session` calls `open/1` at init, `send/2` for outgoing requests,
and `normalize_message/2` for every message the transport process
delivers.

#### `StdioTransport`

Local transport for the `codex` executable. It prefers `codex app-server
proxy` against the managed control socket and starts a standalone `codex
app-server` when the proxy is unavailable, unless `proxy_only?` was requested.

- Default executable: `System.find_executable("codex")`
- Standalone default args: `["app-server", "--enable", "realtime_conversation"]`
- Port options: `:binary`, `:exit_status`, `:use_stdio`, `:hide`
- `normalize_message/2`: `{port, {:data, data}}` → `{:data, data}`,
  `{port, {:exit_status, _}}` → `{:closed, ...}`

#### `WebSocketTransport`

GenServer wrapping Mint HTTP + Mint.WebSocket for persistent connections.

**Retry logic:**
- HTTP 429 and 503 trigger automatic retry with exponential backoff
- Respects `Retry-After` header when present
- Default: 2 retry attempts, 250ms base delay, 5s max handshake timeout
- WSS connections auto-configure CA certs via `:public_key.cacerts_get()`

**Connection lifecycle:**
- Handles WebSocket ping/pong automatically
- Acknowledges remote close frames before shutting down
- Monitors owner pid; cleans up on owner death

#### Remote transports (host-provided)

A host application can bridge to remote runners by implementing the
`Transport` behaviour plus its optional remote callbacks. The reference
implementation lives in the host app as `App.Runtime.RemoteClient.CodexTransport`.

**Handle:**
```elixir
%{
  runner_id: binary(),
  owner: pid(),
  transport_id: binary(),
  workspace_id: binary(),
  workspace_root: binary(),
  initialize_bootstrap: :fresh | {:reattached, map(), boolean()},
  next_request_id: pos_integer(),
  acknowledged_through: non_neg_integer(),
  replay: list(),
  replay_gap: non_neg_integer() | nil,
  pending_requests: list()
}
```

**Event subscriptions (on open):**
1. `codex.session.message` — incoming data from remote runner
2. `codex.session.closed` — remote session terminated
3. `codex.session.replay_gap` — bounded replay overflow boundary
4. `remote_client.connection` — remote client disconnected

`open/1` subscribes to all four event patterns, then sends
`codex.session.reattach` with the stable client-manager transport id. The
daemon either opens a fresh app-server or returns cached initialization state
plus retained events, unresolved server requests, the acknowledgement
watermark, the next JSON-RPC request id, and an opaque generation for its
surviving process. Send and ACK requests echo that generation so delayed work
cannot affect a replacement with the same stable transport id.
`send/2` forwards the decoded JSON payload through `codex.session.send`; an
ambiguous Router timeout or post-push disconnect closes only the BEAM-side owner
with a tagged `delivery_uncertain` reason so the durable client-message
correlation is not retried. An ambiguous server-response send remains unresolved
for reattach instead of acknowledging its retained request. Sequenced terminal
closes pass through the retained event acknowledgement barrier before the BEAM
Session stops, allowing the daemon to retain child exits across WebSocket
outages without losing their replay tail. `close/1` only unsubscribes; the daemon
owns app-server lifetime across BEAM deploys.

---

### Protocol Layer

The protocol layer has two parts: a code generator that produces typed
Elixir modules from JSON Schema, and hand-written infrastructure that
parses, routes, and bridges between generated types and the domain model.

#### Generated Code

Located in `lib/codex_ex/app_server/protocol/generated/` under three namespaces:

| Namespace | Contents |
|-----------|----------|
| `shared/` | Envelope types (`ServerNotification`, `ServerRequest`, `ClientNotification`, `ClientRequest`) and shared param/response schemas used across versions |
| `v1/`     | Version 1 protocol schemas (initialize params/response) |
| `v2/`     | Version 2 protocol schemas (thread operations, turn events, token usage, etc.) |

Each generated module provides:
- A `defstruct` with fields matching the JSON Schema properties
- `decode/1` — JSON map → struct (via `Codec.decode_object/3`)
- `encode/1` — struct → JSON map (via `Codec.encode_object/2`)

**Envelope modules** (`ServerNotification`, `ServerRequest`, etc.) are
special: they contain a `@method_specs` map keyed by method name, with
each entry pointing to the params module for that method. They provide
`known_method?/1` for dispatch and `decode/1` which resolves the method
and decodes params through the appropriate module.

#### `Protocol.Generator`

Mix-time code generator that reads JSON Schema files from
`priv/schema/` and writes Elixir source to
`lib/codex_ex/app_server/protocol/generated/`.

**Pipeline:**
1. Load and parse all `.json` schema files (excluding bundle files)
2. Build a module index mapping schema titles to module names
3. For each schema:
   - **Object schemas** → struct module with `@field_specs`, nested
     `defmodule` for `definitions`, `decode/1` and `encode/1`
   - **Envelope schemas** (titles in `ClientNotification`,
     `ClientRequest`, `ServerNotification`, `ServerRequest`) → dispatch
     module with `@method_specs`, `known_method?/1`, method-aware
     `decode/1` / `encode/1`
   - **Other schemas** → passthrough module (`decode` returns value,
     `encode` calls `Codec.encode_value(:plain, ...)`)
4. Format all output files with the project's `.formatter.exs`

**Value spec type algebra:**
```elixir
:plain                      # passthrough (scalars, untyped maps)
{:array, value_spec()}      # list of typed elements
{:module, module()}         # nested object with its own decode/encode
{:nullable, value_spec()}   # nil | inner_spec
```

#### `Protocol.Codec`

Runtime encode/decode engine used by all generated modules.

- `decode_object/3` — takes module, field specs, and a JSON map;
  stringifies keys, walks each field spec calling `decode_value/2`
  recursively, returns `struct(module, attrs)`
- `encode_object/2` — takes a struct and field specs; omits nil optional
  fields, encodes values recursively, returns a string-keyed map
- Recursive type resolution: `:plain` passes through,
  `{:module, mod}` delegates to `mod.decode/1` or `mod.encode/1`,
  `{:array, spec}` maps over lists, `{:nullable, spec}` handles nil

#### `Protocol.Parser`

Routes raw JSON-RPC payloads to the appropriate typed struct.

**Dispatch logic:**
- **Notifications:** if `ServerNotification.known_method?(method)` →
  `%ServerNotification{}`; else → `%GenericNotification{}`
- **Requests:** if `ServerRequest.known_method?(method)` →
  full `ServerRequest.decode(payload)`; else → `%GenericServerRequest{}`

#### `Protocol.Verifier`

Drift detection: regenerates protocol modules to a temp directory and
diffs against the committed `generated/` tree. Reports missing,
unexpected, or changed files. Used in CI to ensure generated code stays
in sync with the schema snapshot.

#### Fallback Types

- `GenericNotification` — `%{method, params}` for unrecognized notification methods
- `GenericServerRequest` — `%{id, method, params}` for unrecognized request methods
- `UnmatchedResponse` — `%{id, payload}` for RPC responses that don't match a pending request

---

### Domain Model

Hand-written structs that normalize generated protocol types into stable,
typed values used throughout the agents subsystem. All follow the same
pattern: `from_protocol/1` accepts either a generated struct or a plain
map, normalizes via `ProtocolValue`, and returns `{:ok, struct}` or
`{:error, {tag, reason}}`.

#### `Thread`

Service object pairing a `Client` pid with a `ThreadSnapshot`.

```elixir
%Thread{client: Client.t(), id: binary(), snapshot: ThreadSnapshot.t()}
```

Provides `refresh` and `list_turns_page` convenience methods. Full history reads
use paginated turns; legacy full-history reads fail explicitly.

#### `ThreadSnapshot`

Full typed snapshot of thread state returned by the server.

**Fields:** `id`, `name`, `status`, `cwd`, `preview`, `source`, `thread_source`,
`cli_version`, `model_provider`, `ephemeral`, `created_at`, `updated_at`,
`turns` (list of `Turn.t()`), `git_info` (`GitInfo.t()` | nil),
`history_mode`, `agent_nickname`, `agent_role`, `path`, `originator`,
`environments`, `daybreak_enabled`.

**Nested:** `ThreadSnapshot.GitInfo` — `%{branch, origin_url, sha}`.
`ThreadSnapshot.Environment` — `%{environment_id, cwd, runtime_workspace_roots}`.
Environment selections preserve unloaded (`nil`) versus empty (`[]`) values;
these fields are metadata and do not select a workspace or enable Daybreak.

#### `Turn`

Snapshot of a single conversation turn.

**Fields:** `id`, `thread_id`, `status`, `items` (list of
`ThreadItem.t()`), `error` (`Turn.Error.t()` | nil).

**Status helpers:** `completed?/1`, `failed?/1`, `interrupted?/1`.

**Legacy input synthesis:** if a legacy server turn payload includes an `input` field
but no `userMessage` item exists in `items`, the module synthesizes one
and prepends it.

#### `ThreadItem`

Two variants:
- `ThreadItem.AgentMessage` — `%{id, type, text, phase, status}` for
  `"agentMessage"` items
- `ThreadItem.Generic` — `%{id, type, attrs}` fallback for all other
  item types

#### `ThreadGoal`

Thread goal with budget tracking.

**Fields:** `thread_id`, `objective`, `status` (`:active` | `:paused` |
`:budget_limited` | `:complete`), `token_budget`, `tokens_used`,
`time_used_seconds`, `created_at`, `updated_at`.

#### `TokenUsage`

Token usage reported via `thread/tokenUsage/updated` notifications.

**Fields:** `last` (`Breakdown.t()`), `total` (`Breakdown.t()`),
`model_context_window`.

**`TokenUsage.Breakdown`:** `input_tokens`, `output_tokens`,
`cached_input_tokens`, `reasoning_output_tokens`, `total_tokens`.

#### `Types`

Shared type definitions:
```elixir
@type json_scalar :: nil | boolean() | integer() | float() | binary()
@type json_value  :: json_scalar() | [json_value()] | %{optional(binary()) => json_value()}
@type json_object :: %{optional(binary()) => json_value()}
@type timestamp   :: integer() | float()
```

---

### Infrastructure Modules

#### `Message`

Extraction helpers for protocol-native messages. Works uniformly across
`ServerNotification`, `ServerRequest`, `GenericNotification`,
`GenericServerRequest`, and `UnmatchedResponse`.

**Extractors:**
- `method_name/1`, `request_id/1`, `resolved_request_id/1`
- `thread_id/1`, `turn_id/1`, `item_id/1` — deep extraction with
  fallback to nested `thread.id`, `turn.id`, `item.id`
- `extract_item/1` → `ThreadItem.from_protocol/1`
- `extract_turn/1` → `Turn.from_protocol/2` (requires thread_id)
- `extract_text_delta/1` — only for `item/agentMessage/delta` method
- `extract_token_usage/1` — only for `thread/tokenUsage/updated` method

All field access goes through `ProtocolValue` for struct/map duality.

#### `ProtocolValue`

Permissive key-lookup bridge between generated structs and plain maps.

**Problem solved:** generated protocol structs use atom keys (often
camelCase from the JSON Schema), while the domain model expects
snake_case atoms. `ProtocolValue.fetch/3` and `get/4` try multiple key
forms:

1. Direct lookup: atom key, string key, camelCase string
2. Fallback scan: all map keys checked against underscore / camelCase /
   extra_keys variants

Also provides `to_json_value/1` for recursive struct → JSON-safe map
conversion and `normalize_map/1` to strip struct metadata.

#### `SchemaSnapshot`

The committed schema and generated bindings were refreshed with `codex-cli 0.154.0`
and `--experimental` on 2026-09-14 (426 schema files). This replaces the unversioned
snapshot extracted in `f4e203e`; that earlier export did not record a CLI version.
The release baseline is documented in the [official changelog](https://learn.chatgpt.com/docs/changelog).

Exports the JSON Schema from the `codex` CLI to
`priv/schema/`.

**Pipeline:**
1. Find `codex` executable
2. Run `codex app-server generate-json-schema --experimental --out <tmp>`
3. Replace existing snapshot directory atomically
4. Report file count

Used as a development-time step before running `Protocol.Generator`.

Run upgrades from the SDK directory:

```bash
codex --version
mix codex.app_server.snapshot_schema
mix codex.app_server.generate_protocol
mix codex.app_server.verify_protocol
```

The deterministic verification task compares generated bindings with the pinned
snapshot; it does not check the installed executable. After an upgrade, export
again to a fresh temporary directory to check both relationships:

```bash
codex_schema_check=$(mktemp -d)
mix codex.app_server.snapshot_schema --output "$codex_schema_check/schema"
diff -rq priv/schema "$codex_schema_check/schema"
mix codex.app_server.verify_protocol --schema-root "$codex_schema_check/schema"
```

Consumers using a local path dependency should refresh Dialyzer's dependency
cache after updating the SDK: run `mix dialyzer --force-check --plt` in the
consumer project. Its lockfile may not change when the SDK's types change.

Nullable request structs preserve explicit `false` fields and encode `nil` as
JSON `null`; omitted nullable params decode to `nil` as well. In particular,
`supportsLunaReserve` must only be sent by a client implementing automatic
fallback, not merely because the protocol now exposes the field.

---

## Data Flow

### Outgoing RPC (e.g. start a thread)

```
Caller
  → Client.start_thread/2  (GenServer.call)
  → handle_call captures `from`, spawns Task
  → Task calls Session.request(session, "thread/start", params, timeout)
  → Session builds JSON-RPC envelope {id: N, method, params}
  → Session encodes via ClientRequest.encode/1
  → Session calls transport_module.send(transport, json_line)
  → Transport delivers bytes (Port / WebSocket / RemoteClient RPC)
  ...
  → Transport receives response bytes
  → Session.normalize_message → {:data, bytes}
  → Session parses newline-delimited JSON
  → Session matches response id to pending request, replies caller
  → Task receives {:ok, result}, calls GenServer.reply(from, {:ok, thread})
```

### Incoming Server Events (streamed turn)

```
Transport receives notification bytes
  → Session parses, sends {:notification, payload} to Client
  → Client parses via Protocol.Parser.parse(:notification, payload)
  → Client broadcasts {:codex_app_server_event, message} to all subscribers
  → If active TurnStream exists for this thread:
      TurnStream receives the event, correlates by turn_id
      → item/started, item/completed → merge into items map
      → item/agentMessage/delta → append to text_deltas
      → thread/tokenUsage/updated → update usage
      → terminal turn event → set event_final_turn from its status
      → When both rpc_final_turn AND event_final_turn set → mark done
      → Waiters receive {:ok, %TurnStream{}} with final state
```

### Server-Initiated Requests (tool approval)

```
Transport receives request bytes
  → Session parses, sends {:request, id, payload} to Client
  → Client parses via Protocol.Parser.parse(:request, payload)
  → Client broadcasts to subscribers
  → Subscriber calls Client.reply_request(client, request_id, reply)
  → Session sends JSON-RPC response with matching id
```

---

## Cross-Cutting Patterns

### Client Pooling

`ClientManager` reuses clients by their effective connection identity. Two
callers with the same transport, launcher, workspace/runner, initialize, and
protocol options get the same `Client` pid. Dead pooled clients drop out of the
registry and are replaced on the next request.

### Stale Client Recovery

Host applications typically wrap thread operations with a stale-client
retry (see `App.Runtime.Execution.SessionRemoteThreadOps.with_stale_client_retry/5`
in the reference host): if the initial attempt returns a stale-session error,
reconnect with a fresh client and retry once.

### Schema → Code Pipeline

```
codex CLI
  → SchemaSnapshot.snapshot/1 → priv/schema/*.json
  → Generator.generate/1 → protocol/generated/{shared,v1,v2}/*.ex
  → Verifier.verify/1 (CI) — regenerates to temp dir, diffs against committed code
```

### Timeout Hierarchy

| Scope | Default | Max |
|-------|---------|-----|
| Single RPC request | 15s | 30min (Session enforces) |
| Turn operations | 30min | 30min |
| TurnStream.wait | 30min | — |
| WebSocket handshake | 5s | — |
| GenServer.call grace | +1s over RPC timeout | — |

---

## File Inventory

### Hand-Written

| File | Role |
|------|------|
| `client.ex` | Core GenServer — domain API, subscriber fan-out, deferred replies |
| `client_manager.ex` | Singleton client pool keyed by effective connection identity |
| `session.ex` | JSON-RPC 2.0 framing, request correlation, line-based parsing |
| `turn_stream.ex` | Per-turn event collector with race-safe buffering |
| `transport.ex` | Behaviour: `open`, `send`, `close`, `normalize_message` |
| `stdio_transport.ex` | Managed-proxy selection with standalone stdio fallback |
| `stdio_proxy_transport.ex` | WebSocket framing through `codex app-server proxy` stdio |
| `websocket_transport.ex` | Mint HTTP + WebSocket with retry on 429/503 |
| `message.ex` | Uniform field extraction across all message types |
| `protocol_value.ex` | Permissive struct/map key lookup bridge |
| `thread.ex` | Service object: Client + ThreadSnapshot |
| `thread_snapshot.ex` | Typed thread state from server (with GitInfo) |
| `thread_goal.ex` | Thread goal with budget tracking |
| `thread_item.ex` | AgentMessage + Generic item variants |
| `turn.ex` | Turn snapshot with input synthesis |
| `token_usage.ex` | Token usage with Breakdown sub-struct |
| `types.ex` | Shared type definitions (json_value, timestamp) |
| `schema_snapshot.ex` | Export JSON Schema from codex CLI |
| `protocol/codec.ex` | Runtime encode/decode with recursive type algebra |
| `protocol/generator.ex` | JSON Schema → Elixir module code generation |
| `protocol/parser.ex` | Notification/request routing to typed structs |
| `protocol/verifier.ex` | Drift detection — regenerate and diff |
| `protocol/generic_notification.ex` | Fallback for unknown notification methods |
| `protocol/generic_server_request.ex` | Fallback for unknown request methods |
| `protocol/unmatched_response.ex` | Wrapper for orphaned RPC responses |

### Generated

Located in `protocol/generated/{shared,v1,v2}/`. Each file is a
single-module Elixir source with `defstruct`, `decode/1`, `encode/1`.
Regenerated by `Protocol.Generator` from JSON Schema snapshots in
`priv/schema/`. Do not edit manually — changes will be
overwritten and flagged by `Protocol.Verifier` in CI.
