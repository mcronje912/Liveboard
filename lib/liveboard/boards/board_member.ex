defmodule Liveboard.Boards.BoardMember do
  use Ecto.Schema
  import Ecto.Changeset

  schema "board_members" do
    field :role, :string, default: "member"

    # Relationships
    belongs_to :board, Liveboard.Boards.Board
    belongs_to :user, Liveboard.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc false
  def changeset(board_member, attrs) do
    board_member
    |> cast(attrs, [:role, :board_id, :user_id])
    |> validate_required([:board_id, :user_id])
    |> validate_inclusion(:role, ["owner", "admin", "member", "viewer"])
    |> unique_constraint([:board_id, :user_id])
  end
end
