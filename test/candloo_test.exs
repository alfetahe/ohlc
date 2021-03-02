defmodule CandlooTest do
  use ExUnit.Case
  doctest Candloo

  test "greets the world" do
    assert Candloo.hello() == :world
  end
end
