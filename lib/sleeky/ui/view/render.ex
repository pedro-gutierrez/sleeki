defmodule Sleeky.Ui.View.Render do
  @moduledoc false

  @self_closing_tags [
    :area,
    :base,
    :br,
    :col,
    :embed,
    :hr,
    :img,
    :input,
    :keygen,
    :link,
    :meta,
    :param,
    :source,
    :track,
    :wbr
  ]

  def render([]), do: ""

  def render({:html, _, _} = view) do
    "<!DOCTYPE html>" <> do_tags(view)
  end

  def render(view), do: do_tags(view)

  defp do_tags({:each, [name: assign, as: alias], [template]}) do
    template = do_tags(template)

    "{% for #{alias} in #{assign} %}#{template}{% endfor %}"
  end

  defp do_tags({tag, attrs, _}) when tag in @self_closing_tags do
    "<#{tag}#{do_attrs(attrs)}>"
  end

  defp do_tags({tag, attrs, children}) do
    "<#{tag}#{do_attrs(attrs)}>#{do_tags(children)}</#{tag}>"
  end

  defp do_tags(elements) when is_list(elements), do: Enum.map(elements, &do_tags/1)

  defp do_tags(value) when is_binary(value) or is_number(value) or is_number(value) do
    value
  end

  defp do_tags(atom) when is_atom(atom), do: to_string(atom)

  defp do_attrs([]), do: ""

  defp do_attrs(attrs) do
    " #{Enum.map_join(attrs, " ", &do_attr/1)}"
  end

  defp do_attr({name, true}) do
    "#{name}"
  end

  defp do_attr({name, value}) when is_boolean(value) do
    "#{name}=#{value}"
  end

  defp do_attr({name, value}) do
    "#{name}=\"#{value}\""
  end
end
