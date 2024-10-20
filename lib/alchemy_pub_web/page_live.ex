defmodule AlchemyPubWeb.PageLive do
  use AlchemyPubWeb, :live_view
  alias Phoenix.PubSub
  alias AlchemyPub.Engine

  def render(assigns) do
    ~H"""
    <div class="flex flex-col min-h-svh md:flex-row justify-start">
      <div class="menu menu-vertical w-64 border-solid border-l-2 border-neutral-700">
        <%= for {[title, _, _date, meta], i} <- @pages |> Enum.with_index() do %>
          <li>
            <.link
              class={@title == title && "active" || ""}
              patch={i == 0 && "/" || "/#{title}"}
            >
              <.icon
                name={"hero-" <> Map.get(meta, "icon", i == 0 && "home-modern" || "document")}
                class="h-5 w-5"
              />
              <%= raw(Map.get(meta, "title")) %>
              <%= if Map.get(meta, "tags", [])
                  |> Enum.any?(fn t -> Engine.urlify(t) == @tag end) do %>
                <span class="badge badge-xs badge-info" />
              <% end %>
            </.link>
          </li>
        <% end %>
        <li>
          <%= for {{year, _}, posts} <- Enum.group_by(@posts, fn [_, _, date | _] -> Date.year_of_era(date) end) |> Enum.sort(:desc) do %>
            <div class="menu-title">
              <.icon name="hero-calendar" class="h-5 w-5 mr-2 mb-1" /><%= year %>
            </div>
            <ul>
              <%= for [title, _, date, meta] <- posts do %>
                <li>
                  <.link
                    class={ @title == title && "active" || ""}
                    patch={"/#{date}/#{title}"}
                  >
                    <%= raw(Map.get(meta, "title")) %>
                    <%= if Map.get(meta, "tags", [])
                      |> Enum.any?(fn t -> Engine.urlify(t) == @tag end) do %>
                      <span class="badge badge-xs badge-info" />
                    <% end %>
                  </.link>
                </li>
              <% end %>
            </ul>
          <% end %>
        </li>
        <li>
          <div class="menu-title"><.icon name="hero-tag" class="h-5 w-5 mr-2 mb-1" />Tags</div>
          <ul>
            <%= for {tag, title} <- @tags do %>
              <li>
                <.link
                  class={@tag == tag && "active" || ""}
                  patch={"/tag/#{tag}"}
                >
                  <%= title %>
                  <%= if Map.get(@meta, "tags", [])
                      |> Enum.any?(fn t -> Engine.urlify(t) == tag end) do %>
                    <span class="badge badge-xs badge-info" />
                  <% end %>
                </.link>
              </li>
            <% end %>
          </ul>
        </li>
      </div>
      <div class="border-solid border-l-2 border-t-2 border-neutral-700" />
      <div class="flex flex-col pb-8 border-solid border-r-2 border-neutral-700">
        <div :if={Map.get(@meta, "banner")} class="w-full bg-cover bg-center h-[25vh]" style={"background-image: url('/images/#{Map.get(@meta, "banner")}'"} />
        <div :if={!Map.get(@meta, "rank") && Map.get(@meta, "date")} class="self-end p-4 italic">published <%= Map.get(@meta, "date") %></div>
        <div class="md:min-w-[32rem] lg:min-w-[40rem] prose p-4 flex-row">
          <%= raw(@content) %>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(AlchemyPub.PubSub, "page_update")
    end

    {:ok, socket |> assign(post_title: "Loading")}
  end

  def handle_params(params, _url, socket) do
    {:noreply, rebuild(socket, params)}
  end

  defp rebuild(socket, params) do
    all = Engine.find_sorted()
    {pages, posts} = all |> Enum.split_with(fn [_, rank | _] -> rank != nil end)
    pages = pages |> Enum.reverse()

    tags =
      for [_, _, _, meta] <- all do
        Map.get(meta, "tags")
      end
      |> List.flatten()
      |> Enum.map(fn t -> {Engine.urlify(t), t} end)
      |> Enum.sort()
      |> Enum.uniq_by(fn {t, _} -> t end)

    matching =
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

    page =
      case matching do
        m when is_list(m) ->
          hd(m) |> Engine.find_title()

        m ->
          m
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
            tag: nil
          )

        {:tag, tag} ->
          {tag, title} = tags |> Enum.find({nil, nil}, fn {t, _} -> t == tag end)

          content =
            (tag &&
               "<h1>Tag: #{title}</h1><ul>" <>
                 (all
                  |> Enum.filter(fn [_, _, _, meta] ->
                    Map.get(meta, "tags", [])
                    |> Enum.any?(fn t -> Engine.urlify(t) == tag end)
                  end)
                  |> Enum.map(fn
                    [title, rank, _, meta] when rank != nil ->
                      "<li><a href=\"/#{title}\">" <> Map.get(meta, "title") <> "</a></li>"

                    [title, _r, date, meta] ->
                      "<li><a href=\"/#{date}/#{title}\">" <>
                        (date |> Date.to_string()) <>
                        ": " <> Map.get(meta, "title") <> "</a></li>"
                  end)
                  |> Enum.join("")) <> "</ul>") ||
              "Tag not found"

          socket
          |> assign(page_title: title, meta: %{}, content: content, title: nil, tag: tag)

        nil ->
          socket
          |> assign(
            page_title: "404",
            meta: %{},
            content: "Nothing here yet",
            title: nil,
            tag: nil
          )
      end

    {pages, posts} =
      case connected?(socket) do
        true -> {pages |> filter_hidden, posts |> filter_hidden}
        false -> {pages |> filter_robot, posts |> filter_robot}
      end

    socket |> assign(posts: posts, pages: pages, tags: tags, params: params)
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

  def handle_info({:add, _title}, socket) do
    {:noreply, socket |> rebuild(socket.assigns.params)}
  end

  def handle_info({:remove, title}, socket) do
    socket =
      cond do
        title == socket.assigns.title -> push_patch(socket, to: "/")
        true -> socket |> rebuild(socket.assigns.params)
      end

    {:noreply, socket}
  end
end
