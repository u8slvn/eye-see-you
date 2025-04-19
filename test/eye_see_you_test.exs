defmodule EyeSeeYouTest do
  use ExUnit.Case
  doctest EyeSeeYou

  test "greets the world" do
    assert EyeSeeYou.hello() == :world
  end
end
