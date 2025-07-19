defmodule LiveboardWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.
  """
  use LiveboardWeb, :html

  embed_templates "page_html/*"
end
