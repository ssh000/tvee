defmodule Tvmaze.Repo.Migrations.CreateEpisodes do
  use Ecto.Migration

  def change do
    create table(:episodes, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :tvmaze_id, :integer
      add :name, :string
      add :summary, :text
      add :image, :json
      add :season, :integer
      add :number, :integer
      add :airstamp, :naive_datetime
      add :airdate, :string
      add :airtime, :string
      add :runtime, :integer
      add :show_id, references(:shows, on_delete: :nothing, type: :uuid)

      timestamps()
    end

    create unique_index(:episodes, [:tvmaze_id])
  end
end
