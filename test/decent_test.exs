defmodule DecentTest do
  use ExUnit.Case
  doctest Decent

  test "greets the world" do
    assert Decent.hello() == :world
  end
end
