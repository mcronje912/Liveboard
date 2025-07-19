defmodule Liveboard.Boards.TaskComment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "task_comments" do
    field :content, :string

    # Relationships
    belongs_to :task, Liveboard.Boards.Task
    belongs_to :user, Liveboard.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc false
  def changeset(task_comment, attrs) do
    task_comment
    |> cast(attrs, [:content, :task_id, :user_id])
    |> validate_required([:content, :task_id, :user_id])
    |> validate_length(:content, min: 1, max: 1000)
  end
end
