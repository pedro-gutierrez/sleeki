defmodule Sleeky.Ui.View.Resolve do
  @moduledoc false

  def resolve({:layout, [name: layout], children}, slots) do
    more_slots =
      for {:slot, [name: name], value} <- children, into: %{} do
        value =
          case value do
            [component] when is_atom(component) -> component
            values when is_list(values) -> values
          end

        {name, value}
      end

    slots = Map.merge(slots, more_slots)

    layout.source() |> resolve(slots)
  end

  def resolve({:slot, _, [name]}, slots) do
    case Map.get(slots, name) do
      nil ->
        {:div, [], []}

      component when is_atom(component) ->
        component.source() |> resolve(slots)

      nodes when is_list(nodes) ->
        resolve(nodes, slots)
    end
  end

  def resolve({:each, attrs, [{_, _, _} = child]}, slots) do
    child = resolve(child, slots)
    {:each, attrs, [child]}
  end

  def resolve({:each, attrs, [component]}, slots) when is_atom(component),
    do: resolve({:each, attrs, [component.source()]}, slots)

  def resolve({tag, attrs, children}, slots),
    do: {tag, attrs, Enum.map(children, &resolve(&1, slots))}

  def resolve(nodes, slots) when is_list(nodes), do: Enum.map(nodes, &resolve(&1, slots))
  def resolve(text, _slots) when is_binary(text), do: text
  def resolve(value, _slots) when is_atom(value) or is_number(value), do: to_string(value)
end
