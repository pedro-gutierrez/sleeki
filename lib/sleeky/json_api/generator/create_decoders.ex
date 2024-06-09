defmodule Sleeky.JsonApi.Generator.CreateDecoders do
  @moduledoc false
  @behaviour Diesel.Generator

  import Sleeky.Decoder

  @impl true
  def generate(api, _) do
    for context <- api.contexts, model <- context.models(), %{name: :create} <- model.actions() do
      module_name = Module.concat(model, JsonApiCreateDecoder)

      rules = %{"id" => [required: true, type: :string, uuid: true]}

      rules =
        for attr when attr.name not in [:id] <- model.attributes(), into: rules do
          {to_string(attr.name), [] |> required(attr) |> attribute_type(attr)}
        end

      rules =
        for rel <- model.parents(), into: rules do
          decoder = Module.concat(rel.target.module, JsonApiRelationDecoder)

          {to_string(rel.name), [] |> required(rel) |> relation_type(decoder)}
        end

      mappings = default_mappings(model)

      quote do
        defmodule unquote(module_name) do
          use Sleeky.Decoder,
            rules: unquote(Macro.escape(rules)),
            mappings: unquote(mappings)
        end
      end
    end
  end
end
