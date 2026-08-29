defmodule CodexEx.AppServer.Protocol.GenericNotification do
  @moduledoc false

  defstruct [:method, params: %{}]

  @type t :: %__MODULE__{
          method: binary() | nil,
          params: term()
        }
end
