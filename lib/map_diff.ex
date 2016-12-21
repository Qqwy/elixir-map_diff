defmodule MapDiff do
  @moduledoc """
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

  """

  @doc """
  This is the single function that MapDiff currently exports.

  It returns a 'patch', which is a map describing the changes between
  `map_a` and `map_b`.

  ## Examples

  If the (nested) map is still the same, it is considered `:equal`:

  ```elixir
  iex> MapDiff.diff(%{my: 1}, %{my: 1})
  %{changed: :equal, value: %{my: 1}}

  ```

  When a key disappears, it is considered `:removed`:

  ```elixir
  iex> MapDiff.diff(%{a: 1}, %{})
  %{changed: :map_change, value: %{a: %{changed: :removed, value: 1}}}

  ```

  When a key appears, it is considered `:added`:

  ```elixir
  iex> MapDiff.diff(%{}, %{b: 2})
  %{changed: :map_change, value: %{b: %{changed: :added, value: 2}}}

  ```

  When the value of a key changes (and the old nor the new value was a map),
  then this is considered a `:primitive_change`.

  ```elixir
  iex> MapDiff.diff(%{b: 3}, %{b: 2})
  %{changed: :map_change,
    value: %{b: %{added: 2, changed: :primitive_change, removed: 3}}}

  ```

  ```elixir
  iex> MapDiff.diff(%{val: 3}, %{val: %{}})
  %{changed: :map_change,
    value: %{val: %{changed: :primitive_change, added: %{}, removed: 3}}}

  ```

  When the value of a key changes, and the old and new values are both maps,
    then this is considered a `:map_change` that can be parsed recursively.

  ```elixir
  iex> MapDiff.diff(%{a: %{}}, %{a: %{b: 1}})
  %{changed: :map_change,
    value: %{a: %{changed: :map_change,
    value: %{b: %{changed: :added, value: 1}}}}}

  ```

  A more complex example, to see what happens with nested maps:

  ```elixir
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

  ```

  It is also possible to compare two structs of the same kind.
  `MapDiff.diff/2` will add a `struct_name` field to the output,
  so you are reminded of the kind of struct whose fields were changed.


  For example, suppose you define the following structs:


  ```elixir
  defmodule Foo do
    defstruct a: 1, b: 2, c: 3
  end

  defmodule Baz do
    defstruct a: "foo", b: "bar", z: "baz"
  end

  ```

  Then the fields of one `Foo` struct can be compared to another:

  ```elixir
  iex> MapDiff.diff(%Foo{}, %Foo{a: 3})
  %{changed: :map_change, struct_name: Foo,
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

  """
  def diff(map_a, map_b)
  def diff(a, a), do: %{changed: :equal, value: a}


  # two structs of the same kind:
  # compare fields,
  # keep track of struct name.
  def diff(a = %struct_name{}, b = %struct_name{}) do
    diff(a |> Map.delete(:__struct__), b |> Map.delete(:__struct__))
    |> Map.put(:struct_name, struct_name)
  end

  # two different structs.
  def diff(a = %_one{}, b = %_other{}) do
    %{changed: :primitive_change, removed: a, added: b}
  end

  # two non-struct maps.
  def diff(a = %{}, b = %{}) do
    {changes, equal?} = Enum.reduce(a, {%{}, true}, &compare(&1, &2, b))
    {changes, equal?} = additions(a, b, changes, equal?)
    equal? && %{changed: :equal, value: a} || %{changed: :map_change, value: changes}
  end

  defp compare({key, _} = el, acc, b) do
    compare(el, acc, b[key], Map.has_key?(b, key))
  end
  defp compare({key, val}, {changes, equal?}, val, true) do
    {Map.put(changes, key, %{changed: :equal, value: val}), equal?}
  end
  defp compare({key, vala}, {changes, equal?}, valb, true) when is_map(vala) and is_map(valb) do
    valueDiff = diff(vala, valb)
    case valueDiff.changed do
      :equal -> {Map.put(changes, key, %{changed: :equal, value: vala}), equal?}
           _ -> {Map.put(changes, key, valueDiff), false}
    end
  end
  defp compare({key, vala}, {changes, _}, valb, true) do
    {Map.put(changes, key, %{changed: :primitive_change, removed: vala, added: valb}), false}
  end
  defp compare({key, vala}, {changes, _}, _, false) do
    {Map.put(changes, key, %{changed: :removed, value: vala}), false}
  end

  # Iterates over all new keys in `b` that were not in `a`, and returns their values
  # in the proper format.
  defp additions(a, b, changes, equal?) do
    Enum.reduce(Map.keys(b) -- Map.keys(a), {changes, equal?}, fn key, {changes, _equal?} ->
      {Map.put(changes, key, %{changed: :added, value: b[key]}), false}
    end)
  end
end
