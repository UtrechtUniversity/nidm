defmodule NidmWeb.DownloadController do

    use NidmWeb, :controller

    def export(conn, params) do
        %{ "path" => path } = params

        case File.exists?(path) do
            false ->
                conn
                |> put_flash(:error, "Could not find export file!")
                |> redirect(to: "/admin/dashboard")
            true ->
                file = File.read!(path)
                conn
                |> put_resp_content_type("application/x-zip-compressed")
                |> put_resp_header("content-disposition", "attachment; filename=\"#{ Path.basename(path )}\"")
                |> send_resp(200, file)
          end
    end

end
