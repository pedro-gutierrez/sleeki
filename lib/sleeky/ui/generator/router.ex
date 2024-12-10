defmodule Sleeky.Ui.Generator.Router do
  @moduledoc false
  @behaviour Diesel.Generator

  import Sleeky.Naming

  @impl true
  def generate(ui, opts) do
    caller = opts[:caller_module]
    module_name = Module.concat(caller, Router)

    conn = var(:conn)

    routes = Enum.map(ui.pages, &route(ui, &1))

    quote do
      defmodule unquote(module_name) do
        @moduledoc false
        use Plug.Router
        import Plug.Conn

        @html "text/html"

        plug(:match)
        plug(:dispatch)

        defp send_html(conn, body, status \\ 200) do
          conn
          |> put_resp_content_type(@html)
          |> send_resp(status, body)
        end

        unquote_splicing(routes)

        match _ do
          send_html(unquote(conn), "<h1>Not Found</h1>", 404)
        end
      end
    end
  end

  defp route(ui, page) do
    conn = var(:conn)
    not_found_view = ui.not_found_view
    error_view = ui.error_view

    quote do
      match unquote(page.path), via: unquote(page.method) do
        case unquote(page.module).data(unquote(conn).params) do
          {:ok, data} ->
            html = unquote(page.module).render(data)
            send_html(unquote(conn), html, 200)

          {:ok, :redirect, path} ->
            conn = put_resp_header(unquote(conn), "location", path)
            send_resp(conn, 302, "")

          {:error, :not_found} ->
            html = unquote(not_found_view).render(unquote(conn).params)
            send_html(unquote(conn), html, 200)

          {:error, other} ->
            html = unquote(error_view).render(unquote(conn).params)
            send_html(unquote(conn), html, 200)
        end
      end
    end
  end
end
