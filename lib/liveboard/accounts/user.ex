defmodule Liveboard.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :password_hash, :string, redact: true
    field :avatar_color, :string, default: "#3B82F6"

    # Relationships
    has_many :created_boards, Liveboard.Boards.Board, foreign_key: :created_by_id
    has_many :board_members, Liveboard.Boards.BoardMember
    has_many :boards, through: [:board_members, :board]
    has_many :assigned_tasks, Liveboard.Boards.Task, foreign_key: :assignee_id
    has_many :created_tasks, Liveboard.Boards.Task, foreign_key: :created_by_id
    has_many :task_comments, Liveboard.Boards.TaskComment
    has_many :activities, Liveboard.Boards.Activity

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :password, :avatar_color])
    |> validate_required([:name, :email])
    |> validate_email()
    |> validate_password()
    |> put_password_hash()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, Liveboard.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 6, max: 72)
  end

  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        # Simple hash for demo (NOT secure for production)
        hash = simple_hash(password)
        put_change(changeset, :password_hash, hash)
      _ ->
        changeset
    end
  end

  # Simple hash function for demo (NOT secure for production)
  defp simple_hash(password) do
    :crypto.hash(:sha256, password) |> Base.encode16() |> String.downcase()
  end
end
