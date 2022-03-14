defmodule Exercise1Test do
  use ExUnit.Case
  doctest Exercise1

  test "greets the world" do
    assert Exercise1.hello() == :world
  end
end
