defmodule Tvmaze.Episode do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  require Logger

  alias Tvmaze.{Repo, Show, User, Episode}

  @fields ~w(tvmaze_id show_id name summary season number image airstamp airdate airtime runtime summary)a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type Ecto.UUID

  schema "episodes" do
    field :tvmaze_id, :integer
    field :name, :string
    field :season, :integer
    field :number, :integer
    field :airstamp, :naive_datetime
    field :airdate, :string
    field :airtime, :string
    field :runtime, :integer
    field :summary, :string
    field :image, :map

    many_to_many :users, User, join_through: "users_episodes", on_replace: :delete
    belongs_to :show, Show

    timestamps()
  end

  def create_or_update(params) do
    case Repo.get_by(Episode, tvmaze_id: params["id"]) do
      nil -> Episode.changeset(%Episode{tvmaze_id: params["id"]}, params)
      episode -> Episode.changeset(episode, params)
    end
    |> Repo.insert_or_update
  end

  def last_watched(show_id, user) do
    user
    |> Repo.preload([episodes: (from ep in Episode, order_by: [desc: :airstamp], where: ep.show_id == ^show_id)])
    |> Map.get(:episodes)
    |> case do
      [] -> nil
      [episode] -> episode
      episodes -> List.first(episodes)
    end
  end

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, @fields)
    |> convert_date(params["airstamp"])
    |> strip_tags(:summary, params["summary"])
    |> validate_required(~w(tvmaze_id show_id name season number)a)
    |> unique_constraint(:tvmaze_id)
  end

  defp convert_date(changeset, nil), do: changeset
  defp convert_date(changeset, timestamp) do
    case NaiveDateTime.from_iso8601(timestamp) do
      {:ok, date} -> put_change(changeset, :airstamp, date)
      {:error, error} -> Logger.error(error)
    end
  end

  defp strip_tags(changeset, _field, nil), do: changeset
  defp strip_tags(changeset, field, text) do
    put_change(changeset, field, HtmlSanitizeEx.strip_tags(text))
  end
end
