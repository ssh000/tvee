defmodule Tvmaze.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Tvmaze.{User, Repo, Show, Episode}

  @fields ~w(telegram_id first_name last_name language_code username active)a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type Ecto.UUID

  schema "users" do
    field :telegram_id, :integer
    field :first_name, :string
    field :last_name, :string
    field :language_code, :string
    field :username, :string
    field :active, :boolean

    many_to_many :shows, Show, join_through: "users_shows", on_replace: :delete
    many_to_many :episodes, Episode, join_through: "users_episodes", on_replace: :delete

    timestamps()
  end

  def update(user_id, options \\ []) do
    case Repo.get_by(User, telegram_id: user_id) do
      nil -> nil
      user ->
        Ecto.Changeset.change(user, options)
        |> Repo.update!
    end
  end

  def create_or_update(params) do
    case Repo.get_by(User, telegram_id: params.id) do
      nil -> User.changeset(%User{}, params)
      user -> User.changeset(user, params)
    end
    |> Repo.insert_or_update
  end

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, @fields)
    |> validate_required(~w(telegram_id)a)
    |> unique_constraint(:telegram_id)
    |> cast_assoc(:shows)
    |> cast_assoc(:episodes)
  end
end
