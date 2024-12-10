defmodule Blogs.Ui.NotFound do
  @moduledoc false
  use Sleeky.Ui.View

  view do
    html do
      head do
        title "Blogs Index Page"
      end

      body do
        h1 "Not found"
      end
    end
  end
end
