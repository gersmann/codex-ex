defmodule CodexEx.AppServer.Protocol.UnmatchedResponse do
  @moduledoc false

  defstruct [:id, :payload]

  @type t :: %__MODULE__{
          id: term(),
          payload: map()
        }
end
