defmodule AlchemyPubWeb.QrController do
  use AlchemyPubWeb, :controller

  alias QRCode.Render.SvgSettings

  def index(conn, %{"data" => data}) do
    conn
    |> put_resp_content_type("image/svg+xml")
    |> send_resp(200, data |> List.wrap() |> Enum.join("/") |> qr)
  end

  defp qr(s) do
    svg_settings = %SvgSettings{
      background_opacity: 1,
      qrcode_color: "#000000",
      flatten: true,
      structure: :minify
    }

    {:ok, qr} =
      s
      |> QRCode.create()
      |> QRCode.render(:svg, svg_settings)

    qr
  end
end
