# MapDiff

[![hex.pm version](https://img.shields.io/hexpm/v/map_diff.svg)](https://hex.pm/packages/map_diff)
[![Build Status](https://travis-ci.org/Qqwy/elixir_map_diff.svg?branch=master)](https://travis-ci.org/Qqwy/elixir_map_diff)
[![Inline docs](http://inch-ci.org/github/qqwy/elixir_map_diff.svg)](http://inch-ci.org/github/qqwy/elixir_map_diff)


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
  
  In the case of a `:map_change`, the resulting map also contains two extra keys: `:added` and `:removed`, which are maps containing all key-value pairs that were added, removed or changed (in this case, they are listed in both maps) at this level. Keys whose values remained equal are thus not listed in these maps.

  In the case of a `:primitive_change`, the resulting map also contains `:added` and `:removed`, but they simply contain the before and after versions of the value stored.
  
  `MapDiff.diff/2` is the single function that MapDiff currently exports.

  It returns a 'patch', which is a map describing the changes between
  `map_a` and `map_b`. This patch always has the key `:changed`, the key `:value` and if `:changed` is `:map_change`, the keys `:added` and `:removed`.

  ## Examples

  If the (nested) map is still the same, it is considered `:equal`:

  ```elixir
  iex> MapDiff.diff(%{my: 1}, %{my: 1})
  %{changed: :equal, value: %{my: 1}}

  ```

  When a key disappears, it is considered `:removed`:

  ```elixir
  iex> MapDiff.diff(%{a: 1}, %{})
  %{changed: :map_change,
  value: %{a: %{changed: :removed, value: 1}}, added: %{}, removed: %{a: 1}}
  ```
  
  When a key appears, it is considered `:added`:

  ```elixir
  iex> MapDiff.diff(%{}, %{b: 2})
  %{changed: :map_change, value: %{b: %{changed: :added, value: 2}}, added: %{b: 2}, removed: %{}}
  ```

  When the value of a key changes (and one or both of the old or new values is not a map),
  then this is considered a `:primitive_change`.

  ```elixir
  iex> MapDiff.diff(%{b: 3}, %{b: 2})
  %{changed: :map_change, value: %{b: %{added: 2, changed: :primitive_change, removed: 3}}, added: %{b: 2}, removed: %{b: 3}}
  ```

  ```elixir
  iex> MapDiff.diff(%{val: 3}, %{val: %{}})
  %{changed: :map_change, value: %{val: %{added: %{}, changed: :primitive_change, removed: 3}}, added: %{val: %{}}, removed: %{val: 3}}
  ```

  When the value of a key changes, and the old and new values are both maps,
    then this is considered a `:map_change` that can be parsed recursively.

  ```elixir
  iex> MapDiff.diff(%{a: %{}}, %{a: %{b: 1}})
  %{changed: :map_change, 
      value: %{a: %{
        added: %{b: 1}, changed: :map_change, removed: %{},
        value: %{b: %{changed: :added, value: 1}}}
      }, 
      added: %{a: %{b: 1}}, 
      removed: %{a: %{}}}
  ```

  A more complex example, to see what happens with nested maps:

  ```elixir
  iex> foo = %{a: 1, b: 2, c: %{d: 3, e: 4, f: 5}}
  iex> bar = %{a: 1, b: 42, c: %{d: %{something_else: "entirely"}, f: 10}}
  iex> MapDiff.diff(foo, bar)
  %{added: %{b: 42, c: %{d: %{something_else: "entirely"}, f: 10}},
    changed: :map_change, removed: %{b: 2, c: %{d: 3, e: 4, f: 5}},
    value: %{a: %{changed: :equal, value: 1},
      b: %{added: 42, changed: :primitive_change, removed: 2},
      c: %{added: %{d: %{something_else: "entirely"}, f: 10},
        changed: :map_change, removed: %{d: 3, e: 4, f: 5},
        value: %{d: %{added: %{something_else: "entirely"},
            changed: :primitive_change, removed: 3},
          e: %{changed: :removed, value: 4},
          f: %{added: 10, changed: :primitive_change, removed: 5}}}}}

  ```

  It is also possible to compare two structs of the same kind.
  `MapDiff.diff/2` will add a `struct_name` field to the output,
  so you are reminded of the kind of struct whose fields were changed.


  For example, suppose you define the following structs:


  ```elixir
  defmodule Foo do
    defstruct a: 1, b: 2, c: 3
  end

  defmodule Bar do
    defstruct a: "foo", b: "bar", z: "baz"
  end
  ```

  Then the fields of one `Foo` struct can be compared to another:

  ```elixir
  iex> MapDiff.diff(%Foo{}, %Foo{a: 3})
%{added: %Foo{a: 3, b: 2, c: 3}, changed: :map_change,
  removed: %Foo{a: 1, b: 2, c: 3}, struct_name: Foo,
  value: %{a: %{added: 3, changed: :primitive_change, removed: 1},
    b: %{changed: :equal, value: 2}, c: %{changed: :equal, value: 3}}}
  ```

  When comparing two different kinds of structs, this of course
  results in a :primitive_change, as they are simply considered
  primitive data types.

  ```elixir
  iex> MapDiff.diff(%Foo{}, %Bar{})
  %{added: %Bar{a: "foo", b: "bar", z: "baz"}, changed: :primitive_change,
    removed: %Foo{a: 1, b: 2, c: 3}}
  ```


## Installation

The package can be installed
by adding `map_diff` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:map_diff, "~> 1.3"}]
end
```

## Changelog
- 1.3.3 Removes unused dependency 'Tensor'.
- 1.3.2 Fixes key => values that were unchanged still showing up in the `added` and `removed` fields. (Issue [#4](https://github.com/Qqwy/elixir_map_diff/issues/4))
- 1.3.1 Fixed README and documentation.
- 1.3.0 Improved doctests, added `:added` and `:removed` fields to see without crawling in the depth what was changed at a `:map_change`.
- 1.2.0 Comparisons with non-maps is now possible (yielding `:primitive_change`s).
- 1.1.1 Refactoring by @andre1sk. Thank you!
- 1.1.0 Allow comparison of struct fields.
- 1.0.0 First stable version.

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/map_diff](https://hexdocs.pm/map_diff).

