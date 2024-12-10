defmodule Sleeky.Ui.Dsl do
  @moduledoc false
  use Diesel.Dsl,
    otp_app: :sleeky,
    root: Sleeky.Ui.Dsl.Ui,
    tags: [
      Sleeky.Ui.Dsl.Page
    ]
end
