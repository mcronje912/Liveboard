defmodule LiveboardWeb.BoardLive.Show do
  use LiveboardWeb, :live_view
  alias Liveboard.{Accounts, Boards}

  @impl true
  def mount(%{"slug" => slug}, session, socket) do
    # Get current user from session
    current_user = 
      case session["user_id"] do
        nil -> nil
        user_id -> Accounts.get_user!(user_id)
      end

    if current_user do
      board = Boards.get_board_by_slug!(slug)
      board_with_data = Boards.get_board_with_columns_and_tasks!(board.id)
      
      {:ok, assign(socket, 
        current_user: current_user,
        board: board_with_data,
        page_title: board.name
      )}
    else
      {:ok, redirect(socket, to: ~p"/login")}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("create_task", %{"column_id" => column_id, "title" => title}, socket) do
    case Boards.create_task(%{
      title: title,
      column_id: column_id,
      created_by_id: socket.assigns.current_user.id
    }) do
      {:ok, _task} ->
        # Reload board data
        board = Boards.get_board_with_columns_and_tasks!(socket.assigns.board.id)
        
        {:noreply, 
         socket
         |> assign(:board, board)
         |> put_flash(:info, "Task created successfully!")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to create task")}
    end
  end

  @impl true
  def handle_event("delete_task", %{"task_id" => task_id}, socket) do
    task = Boards.get_task!(task_id)
    {:ok, _} = Boards.delete_task(task)

    # Reload board data
    board = Boards.get_board_with_columns_and_tasks!(socket.assigns.board.id)
    
    {:noreply, assign(socket, :board, board)}
  end

  @impl true
  def handle_event("move_task", %{"task_id" => task_id, "column_id" => column_id}, socket) do
    case Boards.move_task(task_id, column_id, 1.0) do
      {:ok, _task} ->
        # Reload board data
        board = Boards.get_board_with_columns_and_tasks!(socket.assigns.board.id)
        {:noreply, assign(socket, :board, board)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to move task")}
    end
  end

  @impl true
  def handle_event("move_task_drag", %{"task_id" => task_id, "column_id" => column_id, "position" => position}, socket) do
    case Boards.move_task(task_id, column_id, position) do
      {:ok, _task} ->
        # Reload board data
        board = Boards.get_board_with_columns_and_tasks!(socket.assigns.board.id)
        
        {:noreply, 
         socket
         |> assign(:board, board)
         |> put_flash(:info, "Task moved!")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to move task")}
    end
  end
end
