defmodule Sleeky.Ui.View.Generator.Data do
  @moduledoc false
  @behaviour Diesel.Generator

  @impl true
  def generate(_html, _opts) do
    quote do
      def data(params), do: {:ok, params}

      defoverridable data: 1
    end
  end
end
