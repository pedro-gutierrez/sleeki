defmodule Sleeky.Ui.Dsl.Page do
  @moduledoc false
  use Diesel.Tag

  tag do
    attribute :name, kind: :module
    attribute :at, kind: :string

    attribute :method,
      kind: :atom,
      in: [:get, :post, :put, :delete],
      default: :get,
      required: false
  end
end
