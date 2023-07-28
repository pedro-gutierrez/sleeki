defmodule Sleeki.UI.Client.Collection do
  @moduledoc false

  import Sleeki.UI.Client.Helpers

  alias ESTree.Tools.Builder, as: JS

  def ast(_entity) do
    JS.property(
      items(),
      JS.array_expression([])
    )
  end
end
