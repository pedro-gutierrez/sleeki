defmodule Bee.Context.Helpers do
  @moduledoc false

  import Bee.Inspector

  def ast(repo, auth) do
    flatten([
      imports(),
      pagination_arguments_function(),
      attrs_with_id(),
      ids_function(),
      maybe_id_function(),
      list_function(repo, auth),
      aggregate_function(repo, auth),
      check_allowed_functions(auth)
    ])
  end

  defp imports do
    quote do
      import Ecto.Query
    end
  end

  defp pagination_arguments_function do
    quote do
      defp pagination_arguments(context) do
        sort_field = Map.get(context, :sort_by, :inserted_at)
        sort_direction = Map.get(context, :sort_direction, :asc)
        limit = Map.get(context, :limit, 20)
        offset = Map.get(context, :offset, 0)

        {:ok, sort_field, sort_direction, limit, offset}
      end
    end
  end

  defp attrs_with_id do
    attrs = var(:attrs)

    [
      quote do
        defp with_id(%{id: _} = unquote(attrs)), do: unquote(attrs)
      end,
      quote do
        defp with_id(unquote(attrs)), do: Map.put(unquote(attrs), :id, Ecto.UUID.generate())
      end
    ]
  end

  defp ids_function do
    [
      quote do
        defp ids(id) when is_binary(id), do: [id]
      end,
      quote do
        defp ids(ids) when is_list(ids), do: ids
      end
    ]
  end

  defp maybe_id_function do
    [
      quote do
        defp maybe_id(nil), do: nil
      end,
      quote do
        defp maybe_id(%{id: id}), do: id
      end
    ]
  end

  defp list_function(repo, auth) do
    quote do
      defp list(query, entity, context) do
        with query <- unquote(auth).scope_query(entity.name(), :list, query, context),
             {:ok, sort_field, sort_direction, limit, offset} <- pagination_arguments(context),
             {:ok, query} <-
               entity.paginate_query(query, sort_field, sort_direction, limit, offset),
             {:ok, query} <- entity.preload_query(query) do
          {:ok, unquote(repo).all(query)}
        end
      end
    end
  end

  defp aggregate_function(repo, auth) do
    quote do
      defp aggregate(query, entity, context) do
        with query <- unquote(auth).scope_query(entity.name(), :list, query, context) do
          {:ok, %{count: unquote(repo).aggregate(query, :count)}}
        end
      end
    end
  end

  defp check_allowed_functions(auth) do
    [
      quote do
        defp check_allowed(nil, _, _, _), do: {:error, :not_found}
      end,
      quote do
        defp check_allowed(item, entity, action, context) do
          context = Map.put(context, entity.name(), item)

          with :ok <- unquote(auth).allowed?(entity.name(), action, context) do
            {:ok, item}
          end
        end
      end
    ]
  end

  def context_with_parents(entity) do
    context = var(:context)

    for rel <- entity.parents() do
      var = var(rel.name)

      quote do
        unquote(context) <- Map.put(unquote(context), unquote(rel.name), unquote(var))
      end
    end
  end

  def attrs_with_required_parents(entity) do
    attrs = var(:attrs)

    for rel <- entity.parents() |> Enum.filter(& &1.required) do
      column = rel.column
      var = var(rel.name)

      quote do
        unquote(attrs) <- Map.put(unquote(attrs), unquote(column), unquote(var).id)
      end
    end
  end

  def attrs_with_optional_parents(entity) do
    attrs = var(:attrs)

    for rel <- entity.parents() |> Enum.reject(& &1.required) do
      column = rel.column
      var = var(rel.name)

      quote do
        unquote(attrs) <- Map.put(unquote(attrs), unquote(column), maybe_id(unquote(var)))
      end
    end
  end

  def context_with_args do
    context = var(:context)
    attrs = var(:attrs)

    quote do
      unquote(context) <- Map.put(unquote(context), :args, unquote(attrs))
    end
  end

  def allowed?(entity, action, auth) do
    context = var(:context)

    quote do
      :ok <- unquote(auth).allowed?(unquote(entity.name()), unquote(action), unquote(context))
    end
  end

  def parent_function_args(entity) do
    for rel <- entity.parents() do
      quote do
        %unquote(rel.target.module){} = unquote(var(rel.name))
      end
    end
  end
end
