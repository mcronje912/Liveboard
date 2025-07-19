defmodule Liveboard.Repo.Migrations.CreateLiveboardSchema do
  use Ecto.Migration

  def change do
    # Users table
    create table(:users) do
      add :name, :string, null: false
      add :email, :string, null: false
      add :password_hash, :string, null: false
      add :avatar_color, :string, default: "#3B82F6"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])

    # Boards table
    create table(:boards) do
      add :name, :string, null: false
      add :description, :text
      add :color, :string, default: "#3B82F6"
      add :slug, :string, null: false
      add :created_by_id, references(:users, on_delete: :nothing), null: false
      add :is_public, :boolean, default: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:boards, [:slug])
    create index(:boards, [:created_by_id])

    # Columns table
    create table(:columns) do
      add :board_id, references(:boards, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :position, :integer, null: false
      add :color, :string, default: "#6B7280"
      add :limit_wip, :integer

      timestamps(type: :utc_datetime)
    end

    create index(:columns, [:board_id])
    create index(:columns, [:board_id, :position])

    # Tasks table
    create table(:tasks) do
      add :column_id, references(:columns, on_delete: :delete_all), null: false
      add :title, :string, null: false
      add :description, :text
      add :priority, :string, default: "medium"
      add :assignee_id, references(:users, on_delete: :nilify_all)
      add :created_by_id, references(:users, on_delete: :nothing), null: false
      add :due_date, :date
      add :position, :float, null: false
      add :estimated_hours, :integer
      add :actual_hours, :integer
      add :tags, {:array, :string}, default: []

      timestamps(type: :utc_datetime)
    end

    create index(:tasks, [:column_id])
    create index(:tasks, [:column_id, :position])
    create index(:tasks, [:assignee_id])
    create index(:tasks, [:created_by_id])

    # Board members table
    create table(:board_members) do
      add :board_id, references(:boards, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :role, :string, default: "member"

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:board_members, [:board_id, :user_id])
    create index(:board_members, [:board_id])
    create index(:board_members, [:user_id])

    # Task comments table
    create table(:task_comments) do
      add :task_id, references(:tasks, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :content, :text, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:task_comments, [:task_id])
    create index(:task_comments, [:user_id])

    # Activities table
    create table(:activities) do
      add :board_id, references(:boards, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :action, :string, null: false
      add :details, :map

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:activities, [:board_id])
    create index(:activities, [:user_id])
    create index(:activities, [:inserted_at])
  end
end
