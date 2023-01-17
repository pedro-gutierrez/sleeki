defmodule Bee.UI.View.Resolve do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      def render(args \\ %{}) do
        html =
          args
          |> resolve()
          |> Bee.Html.render()
      end

      def definition, do: @definition

      def resolve(args \\ %{}) do
        with {node, attrs, children} when is_list(children) <- resolve(@definition, args) do
          {node, attrs, List.flatten(children)}
        end
      end

      def resolve_slots(slots, args) do
        resolve_slots(slots, args, fn
          {name, _, value} -> {name, value}
          {name, value} -> {name, value}
        end)
      end

      def resolve_slots(slots, args, fun) do
        slots
        |> resolve(args)
        |> case do
          args when is_list(args) -> args
          arg -> [arg]
        end
        |> Enum.map(fun)
        |> Enum.into(%{})
      end

      def resolve({:slot, name, [child]}, args) when is_atom(name) do
        case slot!(name, args) do
          items when is_list(items) ->
            Enum.map(items, fn item ->
              item = Enum.into(item, %{})
              resolve(child, item)
            end)
        end
      end

      def resolve({:slot, [], [name]}, args) when is_atom(name) do
        resolve({:slot, name}, args)
      end

      def resolve({:slot, name}, args) when is_atom(name) do
        name
        |> slot!(args)
        |> resolve(args)
      end

      def resolve({:loop, [], children} = directive, args) do
        entity = entity!(args)
        resolve({:loop, [:items], children}, args)
      end

      def resolve({:loop, path, children}, args) when is_list(path) do
        path = Enum.map_join(path, ".", &to_string/1)

        {:template,
         [
           "x-for": "item in $store.default.#{path}",
           ":key": "item.id"
         ], resolve(children, args)}
      end

      def resolve({:loop, {:slot, _} = path, children}, args) do
        path = resolve(path, args)
        resolve({:loop, path, children}, args)
      end

      def resolve({:loop, path, children}, args) when is_binary(path) do
        path =
          path
          |> sanitize_attr(args)
          |> String.split(".")
          |> Enum.map(&String.to_atom/1)

        resolve({:loop, path, children}, args)
      end

      def resolve({:entity, entity, children}, args) do
        items = entity.plural()
        args = Map.put(args, :__entity__, entity)
        resolve(children, args)
      end

      def resolve({:view, view}, args) do
        Code.ensure_compiled!(view)
        view.resolve(args)
      end

      def resolve({:view, [], [view]}, args) do
        Code.ensure_compiled!(view)
        view.resolve(args)
      end

      def resolve({:view, view, slots}, args) do
        Code.ensure_compiled!(view)
        slots = resolve_slots(slots, args)
        args = args |> Map.take([:__entity__]) |> Map.merge(slots)
        view.resolve(args)
      end

      def resolve({node, attrs, children}, args) do
        {node, attrs |> resolve(args) |> sanitize_attrs(args), resolve(children, args)}
      end

      def resolve({node, children}, args) when is_list(children) do
        {node, [], resolve(children, args)}
      end

      def resolve(nodes, args) when is_list(nodes) do
        for n <- nodes, do: resolve(n, args)
      end

      def resolve({name, value}, args) do
        {name, resolve(value, args)}
      end

      def resolve(other, _args) when is_binary(other) or is_number(other) or is_atom(other) do
        other
      end

      def resolve(other, _args) do
        raise """
        Don't know how to resolve markup:

        #{inspect(other)}

        in view #{__MODULE__}
        """
      end

      defp entity!(args) do
        entity = Map.get(args, :__entity__)

        unless entity do
          raise "View #{inspect(__MODULE__)} is trying to resolve the current entity but not value was provided:
            #{inspect(args)}"
        end

        entity
      end

      defp slot!(name, args) do
        with nil <- Map.get(args, name) do
          raise "View #{inspect(__MODULE__)} is trying to resolve slot #{inspect(name)} but no value was provided:
            #{inspect(args)}"
        end
      end

      defp sanitize_attrs(attrs, args) do
        for {name, value} <- attrs, do: {name, sanitize_attr(value, args)}
      end

      defp sanitize_attr([value], args), do: sanitize_attr(value, args)

      defp sanitize_attr(value, args) when is_binary(value) do
        args = string_keys(args)

        value
        |> Solid.parse!()
        |> Solid.render!(args, strict_variables: true)
        |> to_string
      rescue
        _ ->
          raise "Error rendering attribute #{value} with args #{inspect(Map.keys(args))}"
      end

      defp sanitize_attr(value, _args)
           when is_boolean(value) or is_number(value),
           do: value

      defp sanitize_attr(value, _args) when is_atom(value), do: to_string(value)

      defp string_keys(map) do
        for {key, value} <- map, into: %{}, do: {to_string(key), value}
      end
    end
  end
end
