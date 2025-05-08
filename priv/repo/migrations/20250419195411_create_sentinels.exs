defmodule EyeSeeYou.Repo.Migrations.CreateSentinels do
  use Ecto.Migration

  def change do
    create table(:sentinels, primary_key: false) do
      add :uuid, :binary_id, primary_key: true
      add :name, :string, null: false
      add :interval, :integer, default: 60
      add :config, :map, null: false, default: "{}"

      timestamps()
    end

    create index(:sentinels, [:uuid, :name])
  end
end
