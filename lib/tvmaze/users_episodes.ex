defmodule Tvmaze.UsersEpisodes do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset

  alias Tvmaze.{Episode, User, Repo, UsersEpisodes}

  # @primary_key false
  schema "users_episodes" do
    belongs_to :user, User, [type: :binary_id]
    belongs_to :episode, Episode, [type: :binary_id]

    timestamps()
  end

  def create(telegram_user_id, episode_id) do
    case Repo.get_by(User, telegram_id: telegram_user_id) do
      nil -> {:error, "create: User #{telegram_user_id} not found!"}
      user ->
        UsersEpisodes.changeset(%UsersEpisodes{}, %{user_id: user.id, episode_id: episode_id})
        |> Repo.insert
    end
  end

  def delete(telegram_user_id, episode_id) do
    case Repo.get_by(User, telegram_id: telegram_user_id) do
      nil -> {:error, "create: User #{telegram_user_id} not found!"}
      user ->
        from(record in UsersEpisodes, where: record.user_id == ^user.id and record.episode_id == ^episode_id)
        |> Repo.one
        |> Repo.delete
    end
  end

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, [:user_id, :episode_id])
    |> validate_required([:user_id, :episode_id])
    |> unique_constraint(:episode_id, name: :users_episodes_user_id_episode_id_index)
  end
end
