defmodule Liveboard.Boards do
  @moduledoc """
  The Boards context.
  """

  import Ecto.Query, warn: false
  alias Liveboard.Repo
  alias Liveboard.Boards.{Board, Column, Task, BoardMember, TaskComment, Activity}
  alias Liveboard.Broadcasting

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

        # Broadcast board creation
        Broadcasting.broadcast_board_update(board.id, :board_created, %{board: board})

        {:ok, board}

      error -> error
    end
  end

  @doc """
  Updates a board.
  """
  def update_board(%Board{} = board, attrs) do
    case board
         |> Board.changeset(attrs)
         |> Repo.update() do
      {:ok, updated_board} ->
        Broadcasting.broadcast_board_update(board.id, :board_updated, %{board: updated_board})
        {:ok, updated_board}

      error -> error
    end
  end

  @doc """
  Deletes a board.
  """
  def delete_board(%Board{} = board) do
    case Repo.delete(board) do
      {:ok, deleted_board} ->
        Broadcasting.broadcast_board_update(board.id, :board_deleted, %{board_id: board.id})
        {:ok, deleted_board}

      error -> error
    end
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
    case %Column{}
         |> Column.changeset(attrs)
         |> Repo.insert() do
      {:ok, column} ->
        # If column has a board_id, broadcast the update
        if column.board_id do
          Broadcasting.broadcast_board_update(column.board_id, :column_created, %{column: column})
        end
        {:ok, column}

      error -> error
    end
  end

  @doc """
  Updates a column.
  """
  def update_column(%Column{} = column, attrs) do
    case column
         |> Column.changeset(attrs)
         |> Repo.update() do
      {:ok, updated_column} ->
        Broadcasting.broadcast_board_update(column.board_id, :column_updated, %{column: updated_column})
        {:ok, updated_column}

      error -> error
    end
  end

  @doc """
  Deletes a column.
  """
  def delete_column(%Column{} = column) do
    case Repo.delete(column) do
      {:ok, deleted_column} ->
        Broadcasting.broadcast_board_update(column.board_id, :column_deleted, %{column_id: column.id})
        {:ok, deleted_column}

      error -> error
    end
  end

  # Task functions
  @doc """
  Gets a single task.
  """
  def get_task!(id), do: Repo.get!(Task, id)

  @doc """
  Gets a task with preloaded associations.
  """
  def get_task_with_preloads!(id) do
    Repo.get!(Task, id)
    |> Repo.preload([:column, :assignee, :created_by])
  end

  @doc """
  Creates a task with real-time broadcasting.
  """
  def create_task(attrs \\ %{}) do
    attrs = put_task_position(attrs)

    case %Task{}
         |> Task.changeset(attrs)
         |> Repo.insert() do
      {:ok, task} ->
        # Preload associations
        task = Repo.preload(task, [:column, :assignee, :created_by])

        # Get the board_id from the column
        board_id = get_board_id_from_task(task)

        # Broadcast task creation
        Broadcasting.broadcast_task_created(board_id, task)

        # Create activity
        create_activity(%{
          action: "task_created",
          user_id: task.created_by_id,
          board_id: board_id,
          details: %{task_id: task.id, task_title: task.title}
        })

        {:ok, task}

      error -> error
    end
  end

  @doc """
  Updates a task with real-time broadcasting.
  """
  def update_task(%Task{} = task, attrs) do
    case task
         |> Task.changeset(attrs)
         |> Repo.update() do
      {:ok, updated_task} ->
        # Preload associations after update
        updated_task = Repo.preload(updated_task, [:column, :assignee, :created_by])

        board_id = get_board_id_from_task(updated_task)

        # Broadcast task update
        Broadcasting.broadcast_task_updated(board_id, updated_task)

        {:ok, updated_task}

      error -> error
    end
  end

  @doc """
  Moves a task to a different column/position with real-time broadcasting.
  """
  def move_task(task_id, column_id, position) do
    task = Repo.get!(Task, task_id) |> Repo.preload([:column])
    old_column_id = task.column_id

    case update_task(task, %{
      column_id: String.to_integer(column_id),
      position: position
    }) do
      {:ok, updated_task} ->
        board_id = get_board_id_from_task(updated_task)

        # Broadcast task movement
        Broadcasting.broadcast_task_moved(board_id, updated_task, old_column_id, updated_task.column_id)

        # Create activity
        create_activity(%{
          action: "task_moved",
          user_id: updated_task.created_by_id,  # TODO: Get actual current user
          board_id: board_id,
          details: %{
            task_id: updated_task.id,
            task_title: updated_task.title,
            old_column_id: old_column_id,
            new_column_id: updated_task.column_id
          }
        })

        {:ok, updated_task}

      error -> error
    end
  end

  @doc """
  Deletes a task with real-time broadcasting.
  """
  def delete_task(%Task{} = task) do
    # Ensure we have the column preloaded to get board_id
    task = if Ecto.assoc_loaded?(task.column) do
      task
    else
      Repo.preload(task, [:column])
    end

    board_id = get_board_id_from_task(task)

    case Repo.delete(task) do
      {:ok, deleted_task} ->
        # Broadcast task deletion
        Broadcasting.broadcast_task_deleted(board_id, task.id)

        # Create activity
        create_activity(%{
          action: "task_deleted",
          user_id: task.created_by_id,  # TODO: Get actual current user
          board_id: board_id,
          details: %{task_id: task.id, task_title: task.title}
        })

        {:ok, deleted_task}

      error -> error
    end
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

  # Activity functions
  @doc """
  Creates an activity with real-time broadcasting.
  """
  def create_activity(attrs \\ %{}) do
    case %Activity{}
         |> Activity.changeset(attrs)
         |> Repo.insert() do
      {:ok, activity} ->
        # Preload user for the activity
        activity = Repo.preload(activity, [:user])

        # Broadcast activity
        Broadcasting.broadcast_activity(activity.board_id, activity)
        {:ok, activity}

      error -> error
    end
  end

  @doc """
  Gets recent activities for a board.
  """
  def get_recent_activities(board_id, limit \\ 10) do
    from(a in Activity,
      where: a.board_id == ^board_id,
      order_by: [desc: a.inserted_at],
      limit: ^limit,
      preload: [:user]
    )
    |> Repo.all()
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

  defp get_board_id_from_task(task) do
    if task.column do
      task.column.board_id
    else
      # Load the column if not preloaded
      column = Repo.get!(Column, task.column_id)
      column.board_id
    end
  end
end
