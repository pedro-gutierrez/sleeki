defmodule Sleeky.Ui.View.Parser do
  @moduledoc false
  @behaviour Diesel.Parser

  @impl true
  def parse({:view, _, [child]}, _opts), do: child
end
