defmodule Liveboard.Boards.Task do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tasks" do
    field :title, :string
    field :description, :string
    field :priority, :string, default: "medium"
    field :due_date, :date
    field :position, :float
    field :estimated_hours, :integer
    field :actual_hours, :integer
    field :tags, {:array, :string}, default: []

    # Relationships
    belongs_to :column, Liveboard.Boards.Column
    belongs_to :assignee, Liveboard.Accounts.User
    belongs_to :created_by, Liveboard.Accounts.User
    has_many :task_comments, Liveboard.Boards.TaskComment

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [:title, :description, :priority, :due_date, :position, 
                    :estimated_hours, :actual_hours, :tags, :column_id, 
                    :assignee_id, :created_by_id])
    |> validate_required([:title, :position, :column_id, :created_by_id])
    |> validate_length(:title, min: 1, max: 255)
    |> validate_inclusion(:priority, ["low", "medium", "high", "urgent"])
    |> validate_number(:position, greater_than_or_equal_to: 0)
    |> validate_number(:estimated_hours, greater_than_or_equal_to: 0)
    |> validate_number(:actual_hours, greater_than_or_equal_to: 0)
  end
end
