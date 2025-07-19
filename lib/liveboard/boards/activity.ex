defmodule Liveboard.Boards.Activity do
  use Ecto.Schema
  import Ecto.Changeset

  schema "activities" do
    field :action, :string
    field :details, :map

    # Relationships
    belongs_to :board, Liveboard.Boards.Board
    belongs_to :user, Liveboard.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc false
  def changeset(activity, attrs) do
    activity
    |> cast(attrs, [:action, :details, :board_id, :user_id])
    |> validate_required([:action, :board_id, :user_id])
  end
end
