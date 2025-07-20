defmodule LiveboardWeb.Components.ActivityFeed do
  use Phoenix.Component
  import LiveboardWeb.CoreComponents

  def activity_feed(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border p-4">
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-medium text-gray-900 flex items-center">
          <svg class="w-5 h-5 mr-2 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/>
          </svg>
          Recent Activity
        </h3>
        <div class="flex items-center text-sm text-gray-500">
          <div class="w-2 h-2 bg-green-400 rounded-full animate-pulse mr-2"></div>
          Live Updates
        </div>
      </div>

      <!-- Horizontal Activity Feed for Bottom Layout -->
      <div class="activity-feed-bottom">
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
          <div :for={activity <- Enum.take(@activities, 6)} class="flex items-center space-x-3 p-3 bg-gray-50 rounded-lg">
            <!-- User Avatar -->
            <div class="flex-shrink-0">
              <div class="h-8 w-8 rounded-full flex items-center justify-center text-white text-sm font-medium"
                   style={"background-color: #{activity.user.avatar_color}"}>
                <%= String.upcase(String.at(activity.user.name, 0)) %>
              </div>
            </div>

            <!-- Activity Content -->
            <div class="flex-1 min-w-0">
              <div class="text-sm text-gray-900 truncate">
                <span class="font-medium"><%= activity.user.name %></span>
                <span class="text-gray-600"><%= format_activity_action(activity) %></span>
              </div>
              <div class="text-xs text-gray-500">
                <%= time_ago(activity.inserted_at) %>
              </div>
            </div>
          </div>
        </div>

        <!-- Show More Activities Toggle -->
        <div :if={length(@activities) > 6} class="mt-4 text-center">
          <button
            onclick="toggleMoreActivities()"
            class="text-blue-600 hover:text-blue-800 text-sm font-medium"
            id="show-more-btn"
          >
            Show all <%= length(@activities) %> activities
          </button>
        </div>

        <!-- All Activities (Initially Hidden) -->
        <div id="all-activities" class="hidden mt-4 space-y-2 max-h-60 overflow-y-auto">
          <div :for={activity <- @activities} class="flex items-start space-x-3 p-2 hover:bg-gray-50 rounded">
            <!-- User Avatar -->
            <div class="flex-shrink-0">
              <div class="h-6 w-6 rounded-full flex items-center justify-center text-white text-xs font-medium"
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
        </div>

        <div :if={@activities == []} class="text-center py-8 text-gray-500 text-sm">
          <svg class="w-12 h-12 mx-auto mb-2 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/>
          </svg>
          No recent activity
        </div>
      </div>
    </div>

    <script>
      function toggleMoreActivities() {
        const allActivities = document.getElementById('all-activities');
        const showMoreBtn = document.getElementById('show-more-btn');

        if (allActivities.classList.contains('hidden')) {
          allActivities.classList.remove('hidden');
          showMoreBtn.textContent = 'Show less';
        } else {
          allActivities.classList.add('hidden');
          showMoreBtn.textContent = 'Show all activities';
        }
      }
    </script>
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
        "created \"#{activity.details["task_title"]}\""

      "task_moved" ->
        "moved \"#{activity.details["task_title"]}\""

      "task_deleted" ->
        "deleted \"#{activity.details["task_title"]}\""

      "task_updated" ->
        "updated \"#{activity.details["task_title"]}\""

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
        "#{minutes}m ago"

      diff < 86400 ->
        hours = div(diff, 3600)
        "#{hours}h ago"

      true ->
        days = div(diff, 86400)
        "#{days}d ago"
    end
  end
end
