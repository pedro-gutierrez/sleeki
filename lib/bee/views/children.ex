defmodule Bee.Views.Children do
  @moduledoc false

  import Bee.Inspector
  alias Bee.UI.View

  def ast(_ui, views, _schema) do
    view = module(views, Children)

    definition =
      {:div, [class: "block", "x-data": {:slot, :data}, "x-init": {:slot, :init}],
       [
         {:slot, :items,
          [
            {:p, [],
             [
               {:a, [class: "button is-text", "x-bind:href": {:slot, :url}],
                [
                  {:span, ["x-text": {:slot, :label}], []}
                ]}
             ]}
          ]}
       ]}

    quote do
      defmodule unquote(view) do
        unquote(View.ast(definition))
      end
    end
  end
end
