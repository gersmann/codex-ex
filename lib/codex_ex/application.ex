defmodule CodexEx.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: CodexEx.TaskSupervisor},
      {DynamicSupervisor, name: CodexEx.ClientSupervisor, strategy: :one_for_one},
      CodexEx.AppServer.ClientManager
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: CodexEx.Supervisor)
  end
end
