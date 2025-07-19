defmodule Liveboard.Boards do
  @moduledoc """
  The Boards context.
  """

  import Ecto.Query, warn: false
  alias Liveboard.Repo
  alias Liveboard.Boards.{Board, Column, Task, BoardMember, TaskComment, Activity}

  # Board functions
  @doc """
  Returns the list of boards for a user.
  """
  def list_user_boards(user_id) do
    from(b in Board,
      join: bm in BoardMember, on: bm.board_id == b.id,
      where: bm.user_id == ^user_id,
      preload: [:created_by, :board_members]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single board.
  """
  def get_board!(id), do: Repo.get!(Board, id)

  @doc """
  Gets a board by slug.
  """
  def get_board_by_slug!(slug) do
    Board
    |> Repo.get_by!(slug: slug)
    |> Repo.preload([:created_by, :board_members, :columns])
  end

  @doc """
  Creates a board.
  """
  def create_board(attrs \\ %{}) do
    result = 
      %Board{}
      |> Board.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, board} ->
        # Add creator as board owner
        create_board_member(%{
          board_id: board.id,
          user_id: board.created_by_id,
          role: "owner"
        })
        
        # Create default columns
        create_default_columns(board)
        
        {:ok, board}
      
      error -> error
    end
  end

  @doc """
  Updates a board.
  """
  def update_board(%Board{} = board, attrs) do
    board
    |> Board.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a board.
  """
  def delete_board(%Board{} = board) do
    Repo.delete(board)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking board changes.
  """
  def change_board(%Board{} = board, attrs \\ %{}) do
    Board.changeset(board, attrs)
  end

  # Column functions
  @doc """
  Gets a board with its columns and tasks.
  """
  def get_board_with_columns_and_tasks!(id) do
    Board
    |> Repo.get!(id)
    |> Repo.preload([
      :created_by,
      board_members: [:user],
      columns: [tasks: [:assignee, :created_by]]
    ])
  end

  @doc """
  Creates a column.
  """
  def create_column(attrs \\ %{}) do
    %Column{}
    |> Column.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a column.
  """
  def update_column(%Column{} = column, attrs) do
    column
    |> Column.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a column.
  """
  def delete_column(%Column{} = column) do
    Repo.delete(column)
  end

  # Task functions
  @doc """
  Gets a single task.
  """
  def get_task!(id), do: Repo.get!(Task, id)

  @doc """
  Creates a task.
  """
  def create_task(attrs \\ %{}) do
    attrs = put_task_position(attrs)
    
    %Task{}
    |> Task.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a task.
  """
  def update_task(%Task{} = task, attrs) do
    task
    |> Task.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Moves a task to a different column/position.
  """
  def move_task(task_id, column_id, position) do
    task = Repo.get!(Task, task_id)
    
    update_task(task, %{
      column_id: String.to_integer(column_id),
      position: position
    })
  end

  @doc """
  Deletes a task.
  """
  def delete_task(%Task{} = task) do
    Repo.delete(task)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking task changes.
  """
  def change_task(%Task{} = task, attrs \\ %{}) do
    Task.changeset(task, attrs)
  end

  # Board Member functions
  @doc """
  Creates a board member.
  """
  def create_board_member(attrs \\ %{}) do
    %BoardMember{}
    |> BoardMember.changeset(attrs)
    |> Repo.insert()
  end

  # Private helper functions
  defp create_default_columns(board) do
    default_columns = [
      %{name: "To Do", position: 0, color: "#EF4444"},
      %{name: "In Progress", position: 1, color: "#F59E0B"},
      %{name: "Done", position: 2, color: "#10B981"}
    ]

    Enum.each(default_columns, fn column_attrs ->
      create_column(Map.put(column_attrs, :board_id, board.id))
    end)
  end

  defp put_task_position(%{column_id: column_id} = attrs) when is_binary(column_id) do
    put_task_position(Map.put(attrs, :column_id, String.to_integer(column_id)))
  end

  defp put_task_position(%{column_id: column_id} = attrs) do
    # Get the highest position in the column and add 1
    max_position = 
      from(t in Task, 
        where: t.column_id == ^column_id,
        select: max(t.position)
      )
      |> Repo.one()
      |> case do
        nil -> 0.0
        pos -> pos + 1.0
      end

    Map.put(attrs, :position, max_position)
  end
  
  defp put_task_position(attrs), do: Map.put(attrs, :position, 0.0)
end
