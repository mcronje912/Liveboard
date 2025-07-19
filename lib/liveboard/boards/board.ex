defmodule Liveboard.Boards.Board do
  use Ecto.Schema
  import Ecto.Changeset

  schema "boards" do
    field :name, :string
    field :description, :string
    field :color, :string, default: "#3B82F6"
    field :slug, :string
    field :is_public, :boolean, default: false

    # Relationships
    belongs_to :created_by, Liveboard.Accounts.User
    has_many :board_members, Liveboard.Boards.BoardMember
    has_many :members, through: [:board_members, :user]
    has_many :columns, Liveboard.Boards.Column
    has_many :activities, Liveboard.Boards.Activity

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(board, attrs) do
    board
    |> cast(attrs, [:name, :description, :color, :slug, :is_public, :created_by_id])
    |> validate_required([:name, :created_by_id])
    |> validate_length(:name, min: 1, max: 255)
    |> put_slug()
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/)
    |> unique_constraint(:slug)
  end

  defp put_slug(changeset) do
    case get_change(changeset, :name) do
      nil -> changeset
      name -> put_change(changeset, :slug, slugify(name))
    end
  end

  defp slugify(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.trim("-")
  end
end
