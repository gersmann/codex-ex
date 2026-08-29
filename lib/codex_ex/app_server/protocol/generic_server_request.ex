defmodule CodexEx.AppServer.Protocol.GenericServerRequest do
  @moduledoc false

  defstruct [:id, :method, params: %{}]

  @type t :: %__MODULE__{
          id: term(),
          method: binary() | nil,
          params: term()
        }
end
