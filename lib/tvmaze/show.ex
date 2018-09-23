defmodule Tvmaze.Show do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  require Logger

  alias Tvmaze.{Show, Repo, User, Episode}

  @fields ~w(tvmaze_id name summary status image type genres language runtime schedule externals premiered official_site tvmaze_weight)a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type Ecto.UUID

  schema "shows" do
    field :tvmaze_id, :integer
    field :tvmaze_updated, :naive_datetime
    field :tvmaze_weight, :integer, default: 0
    field :name, :string
    field :premiered, :string
    field :official_site, :string
    field :summary, :string
    field :status, :string
    field :image, :map
    field :type, :string
    field :genres, {:array, :string}
    field :language, :string
    field :runtime, :integer
    field :schedule, :map
    field :externals, :map

    many_to_many :users, User, join_through: "users_shows", on_replace: :delete
    has_many :episodes, Episode

    timestamps()
  end

  def list(user) do
    user
    |> Repo.preload([shows: (from show in Show, order_by: [desc: :tvmaze_weight])])
    |> Map.get(:shows)
  end

  def updates do
    from(ep in Episode, where: ep.airstamp >= ^Timex.to_naive_datetime(Timex.now), preload: [:show], left_join: show in assoc(ep, :show), order_by: [desc: show.tvmaze_weight], limit: 100)
    |> Repo.all
    |> Enum.uniq_by(fn ep -> ep.show.id end)
    |> Enum.take(10)
    |> Enum.map(fn ep -> ep.show end)
  end

  def search(query) do
    case HTTPoison.get("http://api.tvmaze.com/search/shows?q=#{normalize_search(query)}") do
      {:ok, data} ->
        case Poison.decode(data.body) do
          {:ok, result} ->
            result
            |> Enum.take(5)
            |> Enum.map(fn item -> item["show"]["id"] end)
            |> get_shows_by_ids
          {:error, error} -> Logger.error(error)
        end
      {:error, error} -> Logger.error(error)
    end
  end

  def next_episode(show) do
    show
    |> Repo.preload([episodes: (from ep in Episode, where: ep.airstamp >= ^Timex.to_naive_datetime(Timex.now), limit: 1, order_by: [asc: :airstamp])])
    |> Map.get(:episodes)
    |> case  do
      [] -> Show.last_episode(show)
      episodes -> List.first(episodes)
    end
  end

  def last_episode(show) do
    show
    |> Repo.preload([episodes: (from ep in Episode, limit: 1, order_by: [desc: :airstamp])])
    |> Map.get(:episodes)
    |> List.first
  end

  def create_or_update(params) do
    case Repo.get_by(Show, tvmaze_id: params["id"]) do
      nil -> Show.changeset(%Show{tvmaze_id: params["id"]}, params)
      show -> Show.changeset(show, params)
    end
    |> Repo.insert_or_update
  end

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, @fields)
    |> put_change(:official_site, params["officialSite"])
    |> put_change(:tvmaze_weight, params["weight"])
    |> convert_date(params["updated"])
    |> strip_tags(:summary, params["summary"])
    |> validate_required(~w(tvmaze_id name)a)
    |> unique_constraint(:tvmaze_id)
  end

  defp get_shows_by_ids(ids) do
    from(show in Show, where: show.tvmaze_id in ^ids) |> Repo.all
  end

  defp convert_date(changeset, unix_timestamp) do
    case DateTime.from_unix(unix_timestamp) do
      {:ok, date} -> put_change(changeset, :tvmaze_updated, DateTime.to_naive(date))
      {:error, error} -> Logger.error(error)
    end
  end

  defp normalize_search(query) do
    query
    |> String.replace(~r/[^0-9A-Za-z ]/, "")
    |> HtmlSanitizeEx.strip_tags
    |> String.slice(0..20)
  end

  defp strip_tags(changeset, field, text) do
    put_change(changeset, field, HtmlSanitizeEx.strip_tags(text))
  end
end
