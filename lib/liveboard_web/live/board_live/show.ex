defmodule LiveboardWeb.BoardLive.Show do
  use LiveboardWeb, :live_view
  alias Liveboard.{Accounts, Boards, Broadcasting}
  alias LiveboardWeb.Presence
  import LiveboardWeb.Components.ActivityFeed

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

      # Subscribe to real-time updates for this board
      Broadcasting.subscribe_to_board(board.id)

      # Track user presence on this board
      {:ok, _} = Presence.track_user(board.id, current_user.id, %{
        name: current_user.name,
        email: current_user.email,
        avatar_color: current_user.avatar_color,
        joined_at: System.system_time(:second)
      })

      # Get initial presence data
      presences = Presence.list_board_users(board.id)
      online_users = Presence.format_users(presences)

      # Get recent activities
      recent_activities = Boards.get_recent_activities(board.id, 15)

      {:ok, assign(socket,
        current_user: current_user,
        board: board_with_data,
        page_title: board.name,
        presences: presences,
        online_users: online_users,
        user_count: length(online_users),
        recent_activities: recent_activities
      )}
    else
      {:ok, redirect(socket, to: ~p"/login")}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  # Handle real-time broadcasts
  @impl true
  def handle_info({:task_created, %{task: task}}, socket) do
    # Reload board data to include new task
    board = Boards.get_board_with_columns_and_tasks!(socket.assigns.board.id)

    {:noreply,
     socket
     |> assign(:board, board)
     |> put_flash(:info, "✨ New task created!")
     |> push_event("close-all-modals", %{})}
  end

  @impl true
  def handle_info({:task_updated, %{task: _task}}, socket) do
    # Reload board data
    board = Boards.get_board_with_columns_and_tasks!(socket.assigns.board.id)

    {:noreply, assign(socket, :board, board)}
  end

  @impl true
  def handle_info({:task_moved, %{task: task}}, socket) do
    # Reload board data
    board = Boards.get_board_with_columns_and_tasks!(socket.assigns.board.id)

    {:noreply,
     socket
     |> assign(:board, board)
     |> put_flash(:info, "🚀 Task \"#{task.title}\" moved!")}
  end

  @impl true
  def handle_info({:task_deleted, %{task_id: _task_id}}, socket) do
    # Reload board data
    board = Boards.get_board_with_columns_and_tasks!(socket.assigns.board.id)

    {:noreply,
     socket
     |> assign(:board, board)
     |> put_flash(:info, "🗑️ Task deleted!")}
  end

  @impl true
  def handle_info({:new_activity, %{activity: _activity}}, socket) do
    # Reload recent activities
    recent_activities = Boards.get_recent_activities(socket.assigns.board.id, 15)

    {:noreply, assign(socket, :recent_activities, recent_activities)}
  end

  # Handle presence updates
  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    presences = Presence.list_board_users(socket.assigns.board.id)
    online_users = Presence.format_users(presences)

    {:noreply,
     socket
     |> assign(:presences, presences)
     |> assign(:online_users, online_users)
     |> assign(:user_count, length(online_users))}
  end

  # Existing event handlers (FIXED - Close modal after task creation)
  @impl true
  def handle_event("create_task", %{"column_id" => column_id, "title" => title}, socket) do
    case Boards.create_task(%{
      title: title,
      column_id: column_id,
      created_by_id: socket.assigns.current_user.id
    }) do
      {:ok, _task} ->
        # Close modal and show success
        {:noreply,
         socket
         |> push_event("close-modal", %{modal_id: "new-task-modal-#{column_id}"})
         |> put_flash(:info, "Task created successfully!")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to create task")}
    end
  end

  @impl true
  def handle_event("delete_task", %{"task_id" => task_id}, socket) do
    # Get task with preloaded associations
    task = Boards.get_task_with_preloads!(task_id)
    {:ok, _} = Boards.delete_task(task)

    # No need to reload - will get broadcast update
    {:noreply, socket}
  end

  @impl true
  def handle_event("move_task", %{"task_id" => task_id, "column_id" => column_id}, socket) do
    case Boards.move_task(task_id, column_id, 1.0) do
      {:ok, _task} ->
        # No need to reload - will get broadcast update
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to move task")}
    end
  end

  @impl true
  def handle_event("move_task_drag", %{"task_id" => task_id, "column_id" => column_id, "position" => position}, socket) do
    case Boards.move_task(task_id, column_id, position) do
      {:ok, _task} ->
        # No need to reload - will get broadcast update
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to move task")}
    end
  end
end
