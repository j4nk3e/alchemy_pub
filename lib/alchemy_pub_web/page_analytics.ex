defmodule AlchemyPubWeb.DevAnalytics do
  use Phoenix.LiveDashboard.PageBuilder

  import Phoenix.HTML

  alias AlchemyPub.Repo.Visit
  alias Contex.BarChart
  alias Contex.Dataset
  alias Contex.Plot
  alias Phoenix.LiveDashboard.PageBuilder

  @impl PageBuilder
  def render(assigns) do
    ~H"""
    {raw(@plot_count)}
    {raw(@plot_duration)}
    """
  end

  @impl PageBuilder
  def menu_link(_session, _capabilities) do
    {:ok, "Analytics"}
  end

  @impl PageBuilder
  def mount(params, _session, socket) do
    date = params |> Map.get("d", Date.utc_today() |> Date.to_string()) |> Date.from_iso8601!()
    series = params |> Map.get("s")

    data =
      for %Visit{duration: duration, path: page, hour: hour} <- Visit.fetch(date),
          page == series or !series,
          reduce: 0..23 |> Enum.to_list() |> Map.from_keys(%{}) do
        acc ->
          Map.update(acc, hour, %{}, fn m ->
            Map.update(m, page, {duration, 1}, fn {d, n} -> {d + duration, n + 1} end)
          end)
      end

    pages =
      data |> Map.values() |> Enum.flat_map(&Map.keys/1) |> MapSet.new() |> MapSet.to_list()

    dataset_d = dataset(data, pages, 0)
    dataset_c = dataset(data, pages, 1)

    {:ok,
     socket
     |> assign(
       plot_duration: plot(pages, dataset_d, "seconds"),
       plot_count: plot(pages, dataset_c, "count"),
       pages: pages,
       datasets: {dataset_d, dataset_c}
     )}
  end

  defp dataset(data, pages, e) do
    data
    |> Enum.map(fn {h, m} ->
      pages
      |> Enum.reduce(m, fn p, acc -> acc |> Map.update(p, 0, &elem(&1, e)) end)
      |> Map.put("hour", h |> to_string())
    end)
    |> Dataset.new()
  end

  defp plot(pages, dataset, y, highlight \\ nil) do
    options = [
      mapping: %{category_col: "hour", value_cols: pages},
      type: :stacked,
      data_labels: true,
      orientation: :vertical,
      phx_event_handler: "chart_bar_clicked",
      colour_palette: :pastel1,
      select_item: highlight
    ]

    Plot.new(dataset, BarChart, 800, 500, options)
    |> Plot.axis_labels("hour", y)
    |> Plot.plot_options(%{legend_setting: :legend_right})
    |> Plot.to_svg()
  end

  @impl true
  def handle_event("chart_bar_clicked", %{"series" => ser}, socket) do
    {d, c} = socket.assigns.datasets

    {:noreply,
     socket
     |> push_navigate(to: "/dev/dashboard/analytics?s=#{ser}")
     |> assign(plot_count: plot(socket.assigns.pages, d, "seconds", %{series: ser}))
     |> assign(plot_duration: plot(socket.assigns.pages, c, "count", %{series: ser}))}
  end
end
