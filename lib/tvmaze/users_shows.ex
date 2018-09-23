defmodule Tvmaze.UsersShows do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset

  alias Tvmaze.{Show, User, Repo, UsersShows}

  # @primary_key false
  schema "users_shows" do
    belongs_to :user, User, [type: :binary_id]
    belongs_to :show, Show, [type: :binary_id]

    timestamps()
  end

  def create(telegram_user_id, show_id) do
    case Repo.get_by(User, telegram_id: telegram_user_id) do
      nil -> {:error, "create: User #{telegram_user_id} not found!"}
      user ->
        UsersShows.changeset(%UsersShows{}, %{user_id: user.id, show_id: show_id})
        |> Repo.insert
    end
  end

  def delete(telegram_user_id, show_id) do
    case Repo.get_by(User, telegram_id: telegram_user_id) do
      nil -> {:error, "create: User #{telegram_user_id} not found!"}
      user ->
        from(record in UsersShows, where: record.user_id == ^user.id and record.show_id == ^show_id)
        |> Repo.one
        |> Repo.delete
    end
  end

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, [:user_id, :show_id])
    |> validate_required([:user_id, :show_id])
    |> unique_constraint(:show_id, name: :users_shows_user_id_show_id_index)
  end
end
