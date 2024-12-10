defmodule Sleeky.Context.Generator.CreateActions do
  @moduledoc false
  @behaviour Diesel.Generator

  import Sleeky.Naming

  @impl true
  def generate(context, _) do
    create_funs(context) ++
      do_create_funs(context) ++ bulk_create_funs(context) ++ create_children_funs(context)
  end

  defp create_funs(context) do
    for model <- context.models, %{name: :create} = action <- model.actions() do
      model_name = model.name()
      action_fun_name = String.to_atom("create_#{model_name}")
      do_action_fun_name = String.to_atom("do_create_#{model_name}")
      children_action_fun_name = String.to_atom("create_#{model_name}_children")
      tasks = action.tasks

      fun_with_map_args =
        quote do
          def unquote(action_fun_name)(attrs, context \\ %{})

          def unquote(action_fun_name)(attrs, context) when is_map(attrs) do
            context = Map.merge(attrs, context)
            repo = repo()

            repo.transaction(fn ->
              with {:ok, model} <- unquote(do_action_fun_name)(attrs, context),
                   :ok <- unquote(children_action_fun_name)(model, attrs, context),
                   :ok <- Sleeky.Job.schedule_all(model, :create, unquote(tasks)) do
                model
              else
                {:error, reason} ->
                  repo.rollback(reason)
              end
            end)
          end
        end

      fun_with_kw_args =
        quote do
          def unquote(action_fun_name)(attrs, context) when is_list(attrs) do
            attrs
            |> Map.new()
            |> unquote(action_fun_name)()
          end
        end

      [fun_with_map_args, fun_with_kw_args]
    end
  end

  defp do_create_funs(context) do
    for model <- context.models, %{name: :create} = action <- model.actions() do
      model_name = model.name()
      action_fun_name = String.to_atom("do_create_#{model_name}")

      attr_names =
        for attr when not attr.computed? <- model.attributes(),
            do: attr.name

      parent_fields =
        for rel when not rel.computed? <- model.parents(),
            into: %{},
            do: {rel.name, rel.column_name}

      default_values =
        for attr when not is_nil(attr.default) <- model.attributes(), into: %{} do
          {attr.name, attr.default}
        end

      quote do
        defp unquote(action_fun_name)(attrs, context) do
          fields =
            attrs
            |> Map.take(unquote(attr_names))
            |> collect_ids(attrs, unquote(Macro.escape(parent_fields)))
            |> Sleeky.Context.Helpers.set_default_values(unquote(Macro.escape(default_values)))
            |> string_keys()
            |> Map.put_new_lazy("id", &Ecto.UUID.generate/0)

          with :ok <- allow(unquote(model_name), unquote(action.name), context) do
            unquote(model).create(fields)
          end
        end
      end
    end
  end

  defp create_children_funs(context) do
    for model <- context.models, %{name: :create} <- model.actions() do
      model_name = model.name()
      action_fun_name = String.to_atom("create_#{model_name}_children")

      child_fields =
        for rel when not rel.computed? <- model.children(),
            do: {rel.name, rel.inverse.name, String.to_atom("create_#{rel.target.name}")}

      quote do
        defp unquote(action_fun_name)(model, attrs, context) do
          context = Map.put(context, unquote(model_name), model)

          unquote(Macro.escape(child_fields))
          |> Enum.reduce([], fn {child_name, inverse_name, create_fun_name}, acc ->
            case Map.get(attrs, child_name) do
              children when is_list(children) ->
                Enum.map(children, &{Map.put(&1, inverse_name, model), create_fun_name})

              nil ->
                []
            end
          end)
          |> List.flatten()
          |> Enum.map(fn {child, create_fun_name} ->
            apply(__MODULE__, create_fun_name, [child, context])
          end)
          |> Enum.reduce_while(:ok, fn
            {:ok, _}, _ -> {:cont, :ok}
            {:error, _} = error, _ -> {:halt, error}
          end)
        end
      end
    end
  end

  defp bulk_create_funs(context) do
    for model <- context.models, %{name: :create} <- model.actions() do
      single_fun_name = String.to_atom("create_#{model.name()}")
      bulk_fun_name = String.to_atom("create_#{model.plural()}")

      quote do
        def unquote(bulk_fun_name)(items, context \\ %{}) when is_list(items) do
          repo = repo()

          with {:ok, :ok} <-
                 repo.transaction(fn ->
                   items
                   |> Enum.reduce_while(nil, fn item, _ ->
                     case unquote(single_fun_name)(item, context) do
                       {:ok, _} -> {:cont, :ok}
                       {:error, _} = error -> {:halt, error}
                     end
                   end)
                   |> then(fn
                     :ok -> :ok
                     {:error, reason} -> repo.rollback(reason)
                   end)
                 end),
               do: :ok
        end
      end
    end
  end
end
