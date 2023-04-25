defmodule Bee.Views.Forms.Delete do
  @moduledoc false

  alias Bee.Entity
  alias Bee.UI.View

  import Bee.Inspector
  import Bee.Views.Components

  def action(entity), do: Entity.action(:delete, entity)

  def ast(_ui, views, entity) do
    form = module(entity.label(), "DeleteForm")
    module_name = module(views, form)
    scope = entity.plural()

    definition =
      {:div, [scope(scope), mode(:delete)],
       [
         {:h1, [data(:name, :display)], []},
         {:strong, [], ["Are you sure?"]},
         button_view(:delete, "Delete"),
         {:p, [],
          [
            link_view("/#{scope}/$id", "Cancel")
          ]}
       ]}

    quote do
      defmodule unquote(module_name) do
        unquote(View.ast(definition))
      end
    end
  end
end
