defmodule Liveboard.Boards.Column do
  use Ecto.Schema
  import Ecto.Changeset

  schema "columns" do
    field :name, :string
    field :position, :integer
    field :color, :string, default: "#6B7280"
    field :limit_wip, :integer

    # Relationships
    belongs_to :board, Liveboard.Boards.Board
    has_many :tasks, Liveboard.Boards.Task, preload_order: [asc: :position]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(column, attrs) do
    column
    |> cast(attrs, [:name, :position, :color, :limit_wip, :board_id])
    |> validate_required([:name, :position, :board_id])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_number(:position, greater_than_or_equal_to: 0)
    |> validate_number(:limit_wip, greater_than: 0)
  end
end
