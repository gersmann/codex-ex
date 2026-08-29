defmodule CodexEx.AppServer.ProtocolValueTest do
  use ExUnit.Case, async: true

  alias CodexEx.AppServer.ProtocolValue

  test "fetch reads snake_case atom keys directly" do
    assert {:ok, 1} = ProtocolValue.fetch(%{thread_id: 1}, :thread_id)
  end

  test "fetch reads snake_case string keys directly" do
    assert {:ok, 2} = ProtocolValue.fetch(%{"thread_id" => 2}, :thread_id)
  end

  test "fetch reads camelCase string keys directly" do
    assert {:ok, 3} = ProtocolValue.fetch(%{"threadId" => 3}, :thread_id)
  end

  test "fetch reads existing camelCase atom keys without exception-driven lookup" do
    assert {:ok, 4} = ProtocolValue.fetch(%{threadId: 4}, :thread_id)
  end
end
