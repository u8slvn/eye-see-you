defmodule EyeSeeYou.Repo.Migrations.CreateSentinels do
  use Ecto.Migration

  def change do
    create table(:sentinels, primary_key: false) do
      add :uuid, :binary_id, primary_key: true
      add :name, :string, null: false
      add :url, :string, null: false
      add :interval, :integer, default: 60
      add :expected_status, :integer, default: 200

      timestamps()
    end

    create index(:sentinels, [:uuid, :name])
  end
end
