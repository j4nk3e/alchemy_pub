defmodule AlchemyPubWeb.PageLive do
  use AlchemyPubWeb, :live_view

  alias AlchemyPub.DeckServer
  alias AlchemyPub.Engine
  alias AlchemyPub.Presence
  alias Phoenix.PubSub
  alias Phoenix.Socket.Broadcast

  @topic "online_users"

  defp active_class, do: "menu-active"

  @impl true
  def mount(_params, %{"session_id" => session_id, "referrer" => referrer} = session, socket) do
    admin_secret = Application.get_env(:alchemy_pub, :admin_secret)
    admin = admin_secret && session["admin_secret"] == admin_secret

    if connected?(socket) do
      PubSub.subscribe(AlchemyPub.PubSub, "page_update")
      PubSub.subscribe(AlchemyPub.PubSub, @topic)
      PubSub.subscribe(AlchemyPub.PubSub, "deck_state")

      Presence.track(self(), @topic, socket.id, %{
        joined: DateTime.utc_now(),
        source: referrer,
        session: session_id,
        admin: admin
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
       track_valid: false,
       slide: 0,
       follow: false,
       page_count: nil,
       fullscreen: false,
       mute: false,
       all_pages: false,
       admin: admin
     )
     |> stream_configure(:deck, [])
     |> stream(:deck, [])}
  end

  @impl true
  def handle_params(params, uri, socket) do
    parsed_uri = uri |> URI.parse()
    socket = socket |> rebuild(params)
    %{track_valid: track_valid} = socket.assigns

    Presence.update(self(), @topic, socket.id, fn map ->
      Map.merge(map, %{valid: track_valid, path: parsed_uri.path, path_joined: DateTime.utc_now()})
    end)

    {:noreply, socket |> assign(url: uri)}
  end

  defp apply_keypress(param, assigns) do
    %{a: a, f: f, m: m} = params = get_params(assigns)

    case param["key"] do
      "a" -> %{params | a: not a}
      "f" -> %{params | f: not f}
      "m" -> %{params | m: not m}
      "Home" -> %{params | p: 0}
      "End" when assigns.admin -> %{params | p: assigns.page_count}
      "End" -> %{params | p: -1}
      "ArrowRight" -> %{params | p: assigns.slide + 1}
      "ArrowLeft" -> %{params | p: max(0, assigns.slide - 1)}
      "Escape" -> %{params | f: false}
      _ -> params
    end
  end

  def get_params(assigns) do
    p =
      if assigns.follow do
        -1
      else
        get_in(assigns.slide) || 0
      end

    f = get_in(assigns.fullscreen) || false
    m = get_in(assigns.mute) || false
    a = get_in(assigns.all_pages) || false
    %{a: a, p: p, f: f, m: m}
  end

  @impl true
  def handle_event("key", param, socket) do
    params = apply_keypress(param, socket.assigns)

    socket =
      if params && socket.assigns.meta["rank"] == :deck do
        socket
        |> push_patch(
          to: "/#{socket.assigns.title}?#{URI.encode_query(params)}",
          replace: true
        )
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("jump", %{"slide" => num}, socket) do
    params = get_params(socket.assigns) |> Map.merge(%{p: num, f: true, a: false})

    socket =
      socket
      |> push_patch(to: "/#{socket.assigns.title}?#{URI.encode_query(params)}", replace: true)

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

  @impl true
  def handle_info(%AlchemyPub.DeckState{name: name}, socket) do
    title = socket.assigns.title
    params = get_params(socket.assigns)

    socket =
      if title == name && !socket.assigns.admin && socket.assigns.follow do
        socket
        |> push_patch(to: "/#{title}?#{URI.encode_query(%{params | p: -1})}", replace: true)
      else
        socket
      end

    {:noreply, socket}
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
        {title, :deck, _date, meta, content} ->
          build_deck(socket, params, {title, meta, content})

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

  defp build_deck(socket, params, {title, meta, content}) do
    page_count = DeckServer.get_count(title)
    %{admin: admin, slide: slide} = socket.assigns
    {slide, direction} = match_slide(params, title, slide, page_count, admin)

    fullscreen = params["f"] == "true"
    mute = params["m"] == "true"
    all_pages = params["a"] == "true" && admin
    follow = params["p"] == "-1" && !admin

    socket =
      socket
      |> assign(
        page_title: meta |> Map.get("title"),
        meta: meta,
        title: title,
        content: "",
        tag: nil,
        track_valid: true,
        slide: slide,
        follow: follow,
        fullscreen: fullscreen && !all_pages,
        mute: mute && !all_pages,
        all_pages: all_pages,
        page_count: page_count
      )

    if all_pages do
      content
      |> Enum.with_index()
      |> Enum.reduce(socket, fn {p, num}, socket ->
        stream_insert(
          socket,
          :deck,
          %{
            id: "deck-page-#{Ulid.generate()}",
            num: num,
            slide: p,
            animation: ""
          },
          at: -1,
          limit: -page_count
        )
      end)
    else
      socket |> stream_insert(:deck, paginate(content, slide, direction, mute), at: -1, limit: -2)
    end
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

  defp paginate(deck, page, direction, mute) do
    animation =
      case direction do
        :left -> "-translate-x-1/4 scale-90 opacity-0"
        :right -> "translate-x-1/4 scale-110 opacity-0"
        nil -> ""
      end

    %{
      id: "deck-page-#{Ulid.generate()}",
      num: page,
      slide:
        if mute do
          ""
        else
          deck |> Enum.at(page)
        end,
      animation:
        if mute do
          "opacity-0"
        else
          animation
        end
    }
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

  defp match_slide(%{"p" => p}, title, prev_page, page_count, admin) do
    page =
      case Integer.parse(p) do
        {page, _} -> page
        _ -> 0
      end

    page =
      case {admin, page} do
        {true, -1} -> DeckServer.set_page(title, page_count)
        {true, p} -> DeckServer.set_page(title, p)
        {_, -1} -> DeckServer.get_page(title)
        {_, p} -> min(p, DeckServer.get_page(title))
      end

    direction =
      cond do
        prev_page == nil -> nil
        prev_page > page -> :left
        prev_page < page -> :right
        true -> nil
      end

    {page, direction}
  end

  defp match_slide(_, _, _, _, _), do: {0, nil}

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

  defp animation(classes) do
    JS.transition({"ease-in-out duration-150", classes, "opacity-100 scale-100 translate-0"})
  end
end
