defmodule AlchemyPubWeb.PageLive do
  use AlchemyPubWeb, :live_view

  alias AlchemyPub.Engine
  alias AlchemyPub.Presence
  alias Phoenix.PubSub
  alias Phoenix.Socket.Broadcast

  @topic "online_users"

  defp active_class, do: "menu-active"

  @impl true
  def mount(_params, %{"session_id" => session_id, "referrer" => referrer}, socket) do
    if connected?(socket) do
      PubSub.subscribe(AlchemyPub.PubSub, "page_update")
      PubSub.subscribe(AlchemyPub.PubSub, @topic)

      Presence.track(self(), @topic, socket.id, %{
        joined: DateTime.utc_now(),
        source: referrer,
        session: session_id
      })
    end

    copyright = Application.get_env(:alchemy_pub, :copyright)

    {:ok,
     socket
     |> assign(
       copyright: %{
         name: Keyword.get(copyright, :name),
         url: Keyword.get(copyright, :url),
         license: Keyword.get(copyright, :license)
       },
       post_title: "Loading",
       viewers: 0,
       track_valid: false
     )}
  end

  @impl true
  def handle_params(params, uri, socket) do
    uri = uri |> URI.parse()
    socket = socket |> rebuild(params)
    %{track_valid: track_valid} = socket.assigns

    Presence.update(self(), @topic, socket.id, fn map ->
      Map.merge(map, %{valid: track_valid, path: uri.path, path_joined: DateTime.utc_now()})
    end)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:add, _title}, socket) do
    {:noreply, socket |> rebuild(socket.assigns.params)}
  end

  @impl true
  def handle_info({:remove, title}, socket) do
    socket =
      if title == socket.assigns.title do
        push_patch(socket, to: "/")
      else
        socket |> rebuild(socket.assigns.params)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info(%Broadcast{event: "presence_diff"}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:viewers, viewers}, socket) do
    {:noreply, socket |> assign(:viewers, viewers)}
  end

  defp rebuild(socket, params) do
    all = Engine.find_sorted()
    {pages, posts} = all |> Enum.split_with(fn [_, rank | _] -> rank != nil end)
    pages = pages |> Enum.reverse()

    tags = get_unique_tags(all)

    page =
      case match_params(params, pages) do
        [m | _] -> Engine.find_title(m)
        m -> m
      end

    socket =
      case page do
        {title, _rank, _date, meta, content} ->
          socket
          |> assign(
            page_title: meta |> Map.get("title"),
            meta: meta,
            content: content,
            title: title,
            tag: nil,
            track_valid: true
          )

        {:tag, tag} ->
          {tag, title} = tags |> Enum.find({nil, nil}, fn {t, _} -> t == tag end)

          socket
          |> assign(
            page_title: title,
            meta: %{},
            content: build_content(tag, title, all),
            title: nil,
            tag: tag,
            track_valid: true
          )

        nil ->
          socket
          |> assign(
            page_title: "404",
            meta: %{},
            content: "Nothing here yet",
            title: nil,
            tag: nil,
            track_valid: false
          )
      end

    {pages, posts, decks} =
      case connected?(socket) do
        true ->
          visible_pages = pages |> filter_hidden()

          {visible_pages |> filter_rank(), posts |> filter_hidden(),
           visible_pages |> filter_rank(:deck)}

        false ->
          visible_pages = pages |> filter_robot()

          {visible_pages |> filter_rank(), posts |> filter_robot(),
           visible_pages |> filter_rank(:deck)}
      end

    socket |> assign(posts: posts, pages: pages, decks: decks, tags: tags, params: params)
  end

  defp filter_rank(pages, type) when is_atom(type) do
    pages |> Enum.filter(fn [_, rank | _] -> rank == type end)
  end

  defp filter_rank(pages) do
    pages |> Enum.filter(fn [_, rank | _] -> is_integer(rank) end)
  end

  defp filter_hidden(pages) do
    pages |> Enum.filter(fn [_, _, _, meta] -> not Map.get(meta, "hidden", false) end)
  end

  defp filter_robot(pages) do
    pages
    |> Enum.filter(fn [_, _, _, meta] ->
      not (Map.get(meta, "hidden", false) || Map.get(meta, "nobot", false))
    end)
  end

  defp build_content(tag, title, all) do
    (tag &&
       "<h1>Tag: #{title}</h1><ul>" <>
         (all
          |> Enum.filter(fn [_, _, _, meta] ->
            Map.get(meta, "tags", [])
            |> Enum.any?(fn t -> Engine.urlify(t) == tag end)
          end)
          |> Enum.map_join(
            "",
            fn
              [title, rank, _, meta] when rank != nil ->
                "<li><a href=\"/#{title}\">" <> Map.get(meta, "title") <> "</a></li>"

              [title, _r, date, meta] ->
                "<li><a href=\"/#{date}/#{title}\">" <>
                  (date |> Date.to_string()) <>
                  ": " <> Map.get(meta, "title") <> "</a></li>"
            end
          )) <> "</ul>") ||
      "Tag not found"
  end

  defp match_params(params, pages) do
    case params do
      %{"path" => ["tag", tag | _]} ->
        {:tag, Engine.urlify(tag)}

      %{"path" => [a, b | _]} ->
        Engine.find_title(Engine.urlify(b)) || Engine.find_date(a)

      %{"path" => [a | _]} ->
        Engine.find_title(Engine.urlify(a)) || Engine.find_date(a)

      _ ->
        pages |> List.first()
    end
  end

  defp get_unique_tags(all) do
    for [_, _, _, meta] <- all do
      Map.get(meta, "tags")
    end
    |> List.flatten()
    |> Enum.map(fn t -> {Engine.urlify(t), t} end)
    |> Enum.sort()
    |> Enum.uniq_by(fn {t, _} -> t end)
  end
end
