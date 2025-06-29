defmodule AlchemyPubWeb.FeedController do
  use AlchemyPubWeb, :controller

  alias AlchemyPub.Engine
  alias Calendar.DateTime.Format

  def init(opts) do
    opts
  end

  def rfc_date(date),
    do: Calendar.DateTime.from_erl!({Date.to_erl(date), {0, 0, 0}}, "Etc/UTC") |> Format.rfc2822()

  def index(conn, _params) do
    uri = current_url(conn) |> URI.parse()
    link = uri |> Map.put(:path, "/") |> URI.to_string()
    pages = Engine.find_sorted()
    posts = pages |> Enum.filter(fn [_u, rank | _] -> rank == nil end)

    date =
      posts
      |> Enum.map(&Enum.at(&1, 2))
      |> List.first(Date.utc_today())

    items =
      posts
      |> Enum.map_join(
        "\n",
        fn [url, _, date, %{"title" => title}] -> ~s|
    <item>
      <title>#{title}</title>
      <link>#{link}#{date}/#{url}</link>
      <guid>#{date}/#{url}</guid>
      <pubDate>#{rfc_date(date)}</pubDate>
    </item>| end
      )

    conn
    |> put_resp_content_type("application/rss+xml")
    |> send_resp(200, ~s|<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <title>#{uri.host}</title>
    <link>#{link}</link>
    <language>en-en</language>
    <copyright>#{uri.host}</copyright>
    <pubDate>#{rfc_date(date)}</pubDate>
    #{items}
  </channel>
</rss>|)
  end
end
