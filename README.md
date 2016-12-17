# MapDiff

  Calculates the difference between two (nested) maps.

  The idea is very simple:
  One of four things can happen to each key in a map:

  - It remains the same: `:equal`
  - It was not in the original map, but it is in the new one: `:added`
  - It was in the original map, but is no longer in the new one: `:removed`
  - It is in both maps, but its value changed.

  For the fourth variant, MapDiff.diff/2 returns `:primitive_change`
  if the value under the key was 'simply changed',
  and `:map_change` if in both arguments this value itself is a map,
  which means that `MapDiff.diff/2` was called on it recursively.

## Examples

  If the (nested) map is still the same, it is considered `:equal`:

  iex> MapDiff.diff(%{my: 1}, %{my: 1})
  %{changed: :equal, value: %{my: 1}}

  When a key disappears, it is considered `:removed`:

  iex> MapDiff.diff(%{a: 1}, %{})
  %{changed: :map_change, value: %{a: %{changed: :removed, value: 1}}}

  When a key appears, it is considered `:added`:

  iex> MapDiff.diff(%{}, %{b: 2})
  %{changed: :map_change, value: %{b: %{changed: :added, value: 2}}}

  When the value of a key changes (and the old nor the new value was a map),
  then this is considered a `:primitive_change`.

  iex> MapDiff.diff(%{b: 3}, %{b: 2})
  %{changed: :map_change,
    value: %{b: %{added: 2, changed: :primitive_change, removed: 3}}}

  iex> MapDiff.diff(%{val: 3}, %{val: %{}})
  %{changed: :map_change,
    value: %{val: %{changed: :primitive_change, added: %{}, removed: 3}}}

  When the value of a key changes, and the old and new values are both maps,
    then this is considered a `:map_change` that can be parsed recursively.

  iex> MapDiff.diff(%{a: %{}}, %{a: %{b: 1}})
  %{changed: :map_change,
    value: %{a: %{changed: :map_change,
    value: %{b: %{changed: :added, value: 1}}}}}

  A more complex example, to see what happens with nested maps:

  iex> foo = %{a: 1, b: 2, c: %{d: 3, e: 4, f: 5}}
  iex> bar = %{a: 1, b: 42, c: %{d: %{something_else: "entirely"}, f: 10}}
  iex> MapDiff.diff(foo, bar)
  %{changed: :map_change,
    value: %{a: %{changed: :equal, value: 1},
      b: %{added: 42, changed: :primitive_change, removed: 2},
      c: %{changed: :map_change,
        value: %{d: %{added: %{something_else: "entirely"},
        changed: :primitive_change, removed: 3},
      e: %{changed: :removed, value: 4},
      f: %{added: 10, changed: :primitive_change, removed: 5}}}}}



## Installation

The package can be installed
by adding `map_diff` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:map_diff, "~> 0.1.0"}]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/map_diff](https://hexdocs.pm/map_diff).

