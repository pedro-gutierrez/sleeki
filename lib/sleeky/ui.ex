defmodule Sleeky.Ui do
  @moduledoc false
  use Diesel,
    otp_app: :sleeky,
    dsl: Sleeky.Ui.Dsl,
    generators: [
      Sleeky.Ui.Generator.Router
    ]

  defstruct [:pages, :error_view, :not_found_view]

  defmodule Page do
    @moduledoc false
    defstruct [:method, :path, :module, :runtime]
  end
end
