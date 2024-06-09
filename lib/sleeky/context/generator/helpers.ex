defmodule Sleeky.Context.Generator.Helpers do
  @moduledoc false
  @behaviour Diesel.Generator

  @impl true
  def generate(_, _) do
    [
      collect_ids_fun(),
      collect_values_fun(),
      maybe_filter_fun()
    ]
  end

  defp collect_ids_fun do
    quote do
      defp collect_ids(dest, source, fields) do
        Enum.reduce(fields, dest, fn {field, new_key}, acc ->
          case source do
            %{^field => %{id: id}} -> Map.put(dest, new_key, id)
            _ -> dest
          end
        end)
      end
    end
  end

  defp collect_values_fun do
    quote do
      defp collect_values(dest, source, fields) do
        Enum.reduce(fields, dest, fn field, acc ->
          case source do
            %{^field => values} when is_list(values) -> Map.put(dest, field, values)
            _ -> dest
          end
        end)
      end
    end
  end

  defp maybe_filter_fun do
    quote do
      alias Sleeky.QueryBuilder

      defp maybe_filter(query, model, context) do
        case Map.get(context, :query) do
          nil ->
            query

          filters ->
            builder = QueryBuilder.from_simple_map(model, filters)

            QueryBuilder.build(query, builder)
        end
      end
    end
  end
end
