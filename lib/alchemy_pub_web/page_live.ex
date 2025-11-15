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
       preview: nil,
       mute: false,
       all_pages: false,
       has_next: false,
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
    %{a: a, f: f} = params = get_params(assigns)

    case param["key"] do
      "a" -> %{params | a: not a, f: f && a}
      "f" -> %{params | f: not f, a: a && f}
      "Home" -> %{params | p: 0}
      "End" when assigns.admin -> %{params | p: assigns.page_count}
      "End" -> %{params | p: -1}
      "ArrowRight" -> %{params | p: assigns.slide + 1}
      "ArrowLeft" -> %{params | p: max(0, assigns.slide - 1)}
      "Escape" -> %{params | f: false}
      _ -> nil
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
    a = get_in(assigns.all_pages) || false
    %{a: a, p: p, f: f}
  end

  @impl true
  def handle_event("key", %{"key" => "m"}, socket) do
    params = get_params(socket.assigns)
    mute = !socket.assigns.mute
    DeckServer.set_mute(socket.assigns.title, mute)

    {:noreply,
     socket
     |> assign(mute: mute)
     |> push_patch(
       to: "/#{socket.assigns.title}?#{URI.encode_query(params)}",
       replace: true
     )}
  end

  @impl true
  def handle_event("key", param, socket) do
    params = apply_keypress(param, socket.assigns)

    socket =
      if params && socket.assigns.meta["rank"] == :deck do
        socket
        |> push_patch(
          to: "/#{socket.assigns.title}?#{URI.encode_query(params)}#slide-#{socket.assigns.slide}",
          replace: true
        )
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("jump", %{"slide" => num}, socket) do
    params = get_params(socket.assigns) |> Map.merge(%{p: num, a: false})

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

          {visible_pages |> filter_rank(), posts |> filter_hidden(), visible_pages |> filter_rank(:deck)}

        false ->
          visible_pages = pages |> filter_robot()

          {visible_pages |> filter_rank(), posts |> filter_robot(), visible_pages |> filter_rank(:deck)}
      end

    socket |> assign(posts: posts, pages: pages, decks: decks, tags: tags, params: params)
  end

  defp build_deck(socket, params, {title, meta, content}) do
    %{pages: page_count, mute: mute, slide: admin_slide} = DeckServer.get_state(title)
    admin = socket.assigns.admin
    slide = match_slide(params, title, page_count, admin)

    fullscreen = params["f"] == "true"
    all_pages = params["a"] == "true" && admin
    follow = params["p"] == "-1" && !admin

    preview =
      cond do
        all_pages || !admin -> nil
        slide == page_count -> %{slide: "last"}
        mute && admin -> paginate(content, slide, false, true)
        true -> paginate(content, slide + 1, mute, true)
      end

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
        preview: preview,
        all_pages: all_pages,
        page_count: page_count,
        has_next:
          if admin do
            slide < page_count - 1
          else
            slide < admin_slide
          end
      )

    if all_pages do
      content
      |> Enum.with_index()
      |> Enum.reduce(socket, fn {{p, _}, num}, socket ->
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
      socket
      |> stream_insert(
        :deck,
        paginate(content, slide, mute, false, "opacity-0 saturate-20"),
        at: -1,
        limit: -2
      )
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

  defp paginate(deck, page, mute, preview, animation \\ "opacity-0") do
    slide = deck |> Enum.at(page)

    %{
      id: "deck-page-#{Ulid.generate()}",
      num: page,
      slide:
        cond do
          mute -> ""
          is_tuple(slide) && preview -> slide |> elem(1)
          is_tuple(slide) -> slide |> elem(0)
          preview -> "end of slides"
          true -> slide
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

  defp match_slide(%{"p" => p}, title, page_count, admin) do
    page =
      case Integer.parse(p) do
        {page, _} -> page
        _ -> 0
      end

    case {admin, page} do
      {true, -1} -> DeckServer.set_page(title, page_count)
      {true, p} -> DeckServer.set_page(title, p)
      {_, -1} -> DeckServer.get_state(title).slide
      {_, p} -> min(p, DeckServer.get_state(title).slide)
    end
  end

  defp match_slide(_, _, _, _), do: 0

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
    JS.transition({"ease-in-out duration-300", classes, "opacity-100 scale-100 translate-0"})
  end
end
