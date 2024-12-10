defmodule Sleeky.Ui.ViewTest do
  use ExUnit.Case

  defmodule Div do
    use Sleeky.Ui.View

    view do
      div id: "myDiv", class: "{{ myClass }}" do
        "{{ title }}"
      end
    end
  end

  defmodule Layout do
    use Sleeky.Ui.View

    view do
      header do
        slot(:header)
      end
    end
  end

  defmodule Page do
    use Sleeky.Ui.View

    view do
      layout Layout do
        slot :header do
          Div
        end
      end
    end
  end

  defmodule Items do
    use Sleeky.Ui.View

    view do
      ul do
        each :items, as: :item do
          li do
            "{{ item }}"
          end
        end
      end
    end
  end

  defmodule Item do
    use Sleeky.Ui.View

    view do
      li do
        "{{ item }}"
      end
    end
  end

  defmodule NamedItems do
    use Sleeky.Ui.View

    view do
      ul do
        each :items, as: :item do
          Item
        end
      end
    end
  end

  defmodule Link do
    use Sleeky.Ui.View

    view do
      a href: "{{ link.url }}" do
        "{{ link.title }}"
      end
    end
  end

  defmodule Html do
    use Sleeky.Ui.View

    view do
      html do
        head do
        end

        body do
        end
      end
    end
  end

  describe "html" do
    test "renders liquid variables" do
      params = %{"title" => "Foo", "myClass" => "bar"}

      assert "<div id=\"myDiv\" class=\"bar\">Foo</div>" = Div.render(params)
    end

    test "supports layouts and composition" do
      params = %{"title" => "Foo", "myClass" => "bar"}

      assert "<header><div id=\"myDiv\" class=\"bar\">Foo</div></header>" = Page.render(params)
    end

    test "generates liquid for loops" do
      params = %{"items" => ["one", "two", "three"]}

      assert "<ul><li>one</li><li>two</li><li>three</li></ul>" = Items.render(params)
    end

    test "supports compositions inside loops" do
      params = %{"items" => ["one", "two", "three"]}

      assert "<ul><li>one</li><li>two</li><li>three</li></ul>" = NamedItems.render(params)
    end

    test "renders doctype for html pages" do
      assert "<!DOCTYPE html><html><head></head><body></body></html>" = Html.render()
    end
  end
end
