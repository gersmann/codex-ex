defmodule CodexEx.AppServer.Types do
  @moduledoc false

  @type json_scalar :: nil | boolean() | integer() | float() | binary()
  @type json_value :: json_scalar() | [json_value()] | %{optional(binary()) => json_value()}
  @type json_object :: %{optional(binary()) => json_value()}
  @type timestamp :: integer() | float()
end
