defmodule AlchemyPub.Engine do
  @moduledoc false
  use GenServer

  alias Phoenix.PubSub

  def urlify(content) when is_list(content), do: Enum.map_join(content, "-", &urlify/1)
  def urlify({_, _, l, _}), do: Enum.map_join(l, "-", &urlify/1)

  def urlify(content),
    do:
      content
      |> String.downcase()
      |> String.replace(~r"[^0-9A-Za-z]", " ")
      |> String.split(~r"\s")
      |> Enum.filter(&(String.length(&1) > 0))
      |> Enum.join("-")

  defp find_h1({"h1", _att, content, _meta}) do
    content |> Earmark.transform()
  end

  defp find_h1([content | tl]) do
    find_h1(content) || find_h1(tl)
  end

  defp find_h1({_tag, _att, content, _meta}) do
    find_h1(content)
  end

  defp find_h1(_) do
    nil
  end

  defp compile(md, is_deck) do
    link_headers = fn {h, attrs, content, meta} ->
      id = urlify(content)

      {:replace,
       {h, [{"id", id} | attrs],
        content ++
          [
            " ",
            {"a",
             [
               {"href", "##{id}"},
               {"class", "mr-1 opacity-20 hover:opacity-60 no-underline"},
               {"aria-hidden", "true"},
               {"tabindex", "-1"}
             ], ["#"], meta}
          ], meta}}
    end

    page_split = fn {hr, _attrs, content, meta} ->
      {:replace, {hr, [{"class", "split"}], content, meta}}
    end

    ast =
      Earmark.as_ast!(md,
        pure_links: false,
        wikilinks: true,
        gfm_tables: true
      )

    title = find_h1(ast)

    processors =
      if is_deck do
        [{"hr", page_split}]
      else
        [{"h2", link_headers}, {"h3", link_headers}]
      end

    postprocessor =
      Earmark.Transform.make_postprocessor(
        Earmark.Options.make_options!(registered_processors: processors)
      )

    content =
      ast
      |> Earmark.Transform.map_ast(postprocessor)
      |> Earmark.transform()

    content =
      if is_deck do
        content |> String.split("<hr class=\"split\">")
      else
        content
      end

    {title, content}
  end

  def title(filename, h1, frontmatter) do
    Map.get(frontmatter, "title", h1 || filename)
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @ets :blog_posts

  def find_date(date) do
    case Date.from_iso8601(date) do
      {:ok, d} -> :ets.match(@ets, {:"$1", :_, d, :_, :_}) |> List.first()
      _ -> nil
    end
  end

  def find_title(title) do
    :ets.lookup(@ets, title) |> List.first()
  end

  def find_sorted do
    :ets.match(@ets, {:"$1", :"$2", :"$3", :"$4", :_})
    |> Enum.sort(fn [_, a, b | _], [_, c, d | _] ->
      cond do
        a > c -> true
        a < c -> false
        true -> Date.compare(b, d) != :lt
      end
    end)
  end

  defp remove_post(path) do
    title = path |> Path.basename() |> Path.rootname() |> urlify()
    :ets.delete(@ets, title)
    title
  end

  defp create_or_update_post(path) do
    {frontmatter, md} =
      case YamlFrontMatter.parse_file(path) do
        {:ok, frontmatter, md} -> {frontmatter, md}
        {:error, _} -> {%{}, File.read!(path)}
      end

    is_deck = frontmatter |> Map.get("deck", false)
    rank = frontmatter |> Map.get("rank", (is_deck && :deck) || nil)
    tags = frontmatter |> Map.get("tags", []) |> List.wrap()
    qr = frontmatter |> Map.get("qr", rank == :deck)

    date =
      with d when is_binary(d) <- frontmatter |> Map.get("date"),
           {:ok, d} <- Date.from_iso8601(d) do
        d
      else
        _ ->
          {{y, m, d}, {_h, _m, _s}} = File.lstat!(path, time: :local).mtime
          Date.new!(y, m, d)
      end

    {h1, content} = compile(md, is_deck)
    filename = path |> Path.basename() |> Path.rootname()
    title = title(filename, h1, frontmatter)
    url = urlify(filename)

    if is_deck do
      AlchemyPub.DeckSupervisor.remove_child(url)
      AlchemyPub.DeckSupervisor.add_child({url, length(content)})
    end

    meta =
      frontmatter
      |> Map.merge(%{
        "title" => title,
        "date" => date,
        "rank" => rank,
        "tags" => tags,
        "qr" => qr
      })

    post = {url, rank, date, meta, content}
    :ets.insert(@ets, post)
    post
  end

  def init(base_path: path) do
    {:ok, watcher_pid} = FileSystem.start_link(dirs: [path], name: :file_watcher)
    FileSystem.subscribe(watcher_pid)

    :ets.new(@ets, [:set, :named_table])
    files = Path.wildcard("#{path}/**/*.md")

    entries =
      for f <- files, path = Path.expand(f) do
        create_or_update_post(path)
      end

    {:ok, entries}
  end

  def handle_info({:file_event, _watcher_pid, {path, events}}, state) do
    for e <- events |> Enum.filter(fn e -> e != :closed end) |> Enum.dedup() do
      case e do
        :moved_from ->
          title = remove_post(path)
          PubSub.broadcast(AlchemyPub.PubSub, "page_update", {:remove, title})

        value when value in [:created, :moved_to, :modified] ->
          title = create_or_update_post(path) |> elem(0)
          PubSub.broadcast(AlchemyPub.PubSub, "page_update", {:add, title})
      end
    end

    {:noreply, state}
  end

  def handle_info({:file_event, _watcher_pid, :stop}, state) do
    {:noreply, state}
  end
end
