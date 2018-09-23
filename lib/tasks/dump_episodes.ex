defmodule Tvmaze.Tasks.DumpEpisodes do
  alias Tvmaze.{Show, Repo, Episode}
  import Ecto.Query
  require Logger

  def run do
    from(show in Show, select: %{tvmaze_id: show.tvmaze_id, id: show.id})
    |> Repo.all
    |> Enum.map(&get_episodes(&1))
  end

  def run(tvmaze_id) do
    from(show in Show, where: show.tvmaze_id == ^tvmaze_id, select: %{tvmaze_id: show.tvmaze_id, id: show.id})
    |> Repo.all
    |> Enum.map(&get_episodes(&1))
  end

  def get_episodes(show) do
    case HTTPoison.get("http://api.tvmaze.com/shows/#{show.tvmaze_id}?embed=episodes") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Poison.decode(body) do
          {:ok, data} ->
            data
            |> get_in(["_embedded", "episodes"])
            |> Enum.map(&Episode.create_or_update(Map.put(&1, "show_id", show.id)))
          {:error, error} -> Logger.error(error)
          _ -> nil
        end
      {:ok, %HTTPoison.Response{status_code: 404, body: body}} -> Logger.error(body)
      {:ok, %HTTPoison.Response{status_code: 429, body: body}} -> Logger.error(body)
      {:error, %HTTPoison.Error{reason: reason}} -> Logger.error(reason)
      _ -> nil
    end
  end
end
