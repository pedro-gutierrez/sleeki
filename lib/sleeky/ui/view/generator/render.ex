defmodule Sleeky.Ui.View.Generator.Render do
  @moduledoc false
  @behaviour Diesel.Generator

  alias Sleeky.Ui.View

  @impl true
  def generate(html, _opts) do
    slots = %{}

    template =
      html
      |> View.Resolve.resolve(slots)
      |> View.Render.render()

    quote do
      @template Solid.parse!(unquote(template))

      def render(args \\ %{}) do
        @template |> Solid.render!(args) |> to_string()
      end
    end
  end
end
