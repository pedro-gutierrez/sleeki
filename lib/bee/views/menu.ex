defmodule Bee.Views.Menu do
  @moduledoc false

  import Bee.Inspector
  alias Bee.UI.View

  def ast(ui, views, schema) do
    view = module(views, Menu)
    definition = definition(ui, schema)

    quote do
      defmodule unquote(view) do
        unquote(View.ast(definition))
      end
    end
  end

  defp definition(ui, schema) do
    nav_view = module(ui, Nav)
    items = Enum.map(schema.entities(), &nav_item/1)

    {:view, nav_view,
     [
       {:items, items}
     ]}
  end

  defp nav_item(entity) do
    [
      onclick: "$store.router.show(\"#{entity.plural}\")",
      class: "$store.router.items == '#{entity.plural}' ? 'bg-indigo-600': 'bg-gray-300'",
      label: Inflex.pluralize(entity.label)
    ]
  end
end
