defmodule Sleeky do
  @moduledoc """
  The `Sleeky` module aggregates and provides common utility functions for handling DSLs (Domain Specific Languages)
  within the Sleeky application. It collects various DSL modules and offers functions to manage their local functions
  and tags.
  """

  @dsls [
    Sleeky.Authorization.Dsl,
    Sleeky.Context.Dsl,
    Sleeky.Model.Dsl,
    Sleeky.Context.Dsl,
    Sleeky.JsonApi.Dsl,
    Sleeky.Endpoint.Dsl,
    Sleeky.Ui.Dsl,
    Sleeky.Ui.Action.Dsl,
    Sleeky.Ui.View.Dsl
  ]

  @doc """
  Returns a sorted list of local functions without parentheses from all the DSL modules.
  """
  def locals_without_parens,
    do: @dsls |> Enum.flat_map(& &1.locals_without_parens()) |> Enum.sort()

  @doc """
  Returns a flat list of tags from all the DSL modules.
  """
  def tags, do: Enum.flat_map(@dsls, & &1.tags())
end
