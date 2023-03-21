defmodule ExHackersTest do
  use ExUnit.Case
  doctest ExHackers

  test "greets the world" do
    assert ExHackers.hello() == :world
  end
end
