defmodule Tvmaze.Repo.Migrations.CreateShows do
  use Ecto.Migration

  def change do
    create table(:shows, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :tvmaze_id, :integer
      add :tvmaze_updated, :naive_datetime
      add :name, :string
      add :summary, :text
      add :status, :string
      add :type, :string
      add :genres, {:array, :string}
      add :language, :string
      add :runtime, :integer
      add :schedule, :json
      add :externals, :json
      add :image, :json

      timestamps()
    end

    create unique_index(:shows, [:tvmaze_id])
  end
end
