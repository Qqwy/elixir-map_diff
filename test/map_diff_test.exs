

defmodule MapDiffTest do
  use ExUnit.Case

  # Simple example structs
  # that are used in some of the doctests.
  defmodule Foo do
    defstruct a: 1, b: 2, c: 3
  end

  defmodule Bar do
    defstruct a: "foo", b: "bar", z: "baz"
  end


  doctest MapDiff
end
