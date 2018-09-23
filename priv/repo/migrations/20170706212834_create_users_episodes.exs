defmodule Tvmaze.Repo.Migrations.CreateUsersEpisodes do
  use Ecto.Migration

  def change do
    create table(:users_episodes) do
      add :user_id, references(:users, type: :uuid), primary_key: true
      add :episode_id, references(:episodes, type: :uuid), primary_key: true

      timestamps()
    end

    create index(:users_episodes, [:user_id, :episode_id], unique: true)
  end
end
