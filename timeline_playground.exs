# timeline_playground.exs

# 安装依赖
Mix.install([
  {:phoenix_playground, "~> 0.1.6"},
  {:phoenix_pubsub, "~> 2.1"}
])

# 定义 LiveView 模块
defmodule TimelineLive do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(temporary_assigns: [form: nil])
      |> stream(:posts, [])
      |> assign(:form, to_form(%{"content" => ""}))

    {:ok, socket}
  end

  def handle_event("create_post", %{"content" => content}, socket) do
    post = %{
      id: System.unique_integer([:positive]),
      content: content,
      inserted_at: DateTime.utc_now()
    }

    socket =
      socket
      |> stream_insert(:posts, post, at: 0)
      |> assign(:form, to_form(%{"content" => ""}))

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="timeline">
      <h1>Timeline</h1>

      <.form for={@form} phx-submit="create_post">
        <textarea name="content" placeholder="What's on your mind?"><%= @form.params["content"] %></textarea>
        <button type="submit">Post</button>
      </.form>

      <div class="posts" phx-update="stream" id="posts">
        <div :for={{id, post} <- @streams.posts} id={id} class="post">
          <p><%= post.content %></p>
          <small><%= post.inserted_at %></small>
        </div>
      </div>
    </div>

    <style>
      .timeline { max-width: 800px; margin: 0 auto; padding: 20px; }
      .post { border: 1px solid #ddd; padding: 10px; margin: 10px 0; }
      form { margin: 20px 0; }
      textarea { width: 100%; min-height: 100px; margin-bottom: 10px; }
    </style>
    """
  end
end

PhoenixPlayground.start(live: TimelineLive)
