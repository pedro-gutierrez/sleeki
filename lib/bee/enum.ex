defmodule Sleeki.Enum do
  @moduledoc false

  import Sleeki.Inspector

  defmacro __using__(values) do
    name = name(__CALLER__.module)

    quote do
      def name, do: unquote(name)
      def values, do: unquote(values)
    end
  end
end
