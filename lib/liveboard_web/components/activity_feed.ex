defmodule LiveboardWeb.Components.ActivityFeed do
  use Phoenix.Component
  import LiveboardWeb.CoreComponents

  def activity_feed(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border p-4">
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-medium text-gray-900">Recent Activity</h3>
        <svg class="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
        </svg>
      </div>

      <div class="space-y-3 max-h-96 overflow-y-auto">
        <div :for={activity <- @activities} class="flex items-start space-x-3">
          <!-- User Avatar -->
          <div class="flex-shrink-0">
            <div class="h-8 w-8 rounded-full flex items-center justify-center text-white text-sm font-medium"
                 style={"background-color: #{activity.user.avatar_color}"}>
              <%= String.upcase(String.at(activity.user.name, 0)) %>
            </div>
          </div>

          <!-- Activity Content -->
          <div class="flex-1 min-w-0">
            <div class="text-sm text-gray-900">
              <span class="font-medium"><%= activity.user.name %></span>
              <%= format_activity_action(activity) %>
            </div>
            <div class="text-xs text-gray-500">
              <%= time_ago(activity.inserted_at) %>
            </div>
          </div>
        </div>

        <div :if={@activities == []} class="text-center py-4 text-gray-500 text-sm">
          No recent activity
        </div>
      </div>
    </div>
    """
  end

  def online_users(assigns) do
    ~H"""
    <div class="flex items-center space-x-3 bg-blue-50 rounded-lg p-3">
      <div class="flex items-center space-x-2">
        <div class="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
        <span class="text-sm font-medium text-gray-700">
          <%= @user_count %> user<%= if @user_count != 1, do: "s" %> online
        </span>
      </div>

      <div class="flex -space-x-2">
        <%= for user <- Enum.take(@users, 5) do %>
          <div class="w-8 h-8 rounded-full border-2 border-white flex items-center justify-center text-white text-sm font-medium shadow-sm"
               style={"background-color: #{user.avatar_color}"}
               title={user.name}>
            <%= String.upcase(String.at(user.name, 0)) %>
          </div>
        <% end %>

        <%= if length(@users) > 5 do %>
          <div class="w-8 h-8 rounded-full border-2 border-white bg-gray-400 flex items-center justify-center text-white text-xs font-medium shadow-sm">
            +<%= length(@users) - 5 %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp format_activity_action(activity) do
    case activity.action do
      "task_created" ->
        "created task \"#{activity.details["task_title"]}\""

      "task_moved" ->
        "moved task \"#{activity.details["task_title"]}\""

      "task_deleted" ->
        "deleted task \"#{activity.details["task_title"]}\""

      "task_updated" ->
        "updated task \"#{activity.details["task_title"]}\""

      _ ->
        "performed an action"
    end
  end

  defp time_ago(datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 ->
        "just now"

      diff < 3600 ->
        minutes = div(diff, 60)
        "#{minutes} min#{ if minutes != 1, do: "s"} ago"

      diff < 86400 ->
        hours = div(diff, 3600)
        "#{hours} hour#{if hours != 1, do: "s"} ago"

      true ->
        days = div(diff, 86400)
        "#{days} day#{if days != 1, do: "s"} ago"
    end
  end
end
