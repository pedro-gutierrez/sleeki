defmodule Sleeky.Ui.Parser do
  @moduledoc false
  @behaviour Diesel.Parser

  alias Sleeky.Ui
  alias Sleeky.Ui.Page

  @impl true
  def parse({:ui, _, pages}, opts) do
    ui = Keyword.fetch!(opts, :caller_module)

    pages =
      for {:page, page, _} <- pages do
        path = Keyword.fetch!(page, :at)
        module = Keyword.fetch!(page, :name)
        method = Keyword.get(page, :method, :get)

        %Page{
          method: method,
          path: path,
          module: module
        }
      end

    error_view = Module.concat(ui, Error)
    not_found_view = Module.concat(ui, NotFound)

    %Ui{pages: pages, error_view: error_view, not_found_view: not_found_view}
  end
end
