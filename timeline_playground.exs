# timeline_playground.exs

# 安装依赖
Mix.install([
  {:phoenix_playground, "~> 0.1.6"}
])

# 定义 LiveView 模块
defmodule TimelineLive do
  use Phoenix.LiveView

  @topic "timeline"

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(PhoenixPlayground.PubSub, @topic)
    end

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

    # 广播新帖子到所有客户端
    Phoenix.PubSub.broadcast(PhoenixPlayground.PubSub, @topic, {:new_post, post})

    socket =
      socket
      |> stream_insert(:posts, post, at: 0)
      |> assign(:form, to_form(%{"content" => ""}))

    {:noreply, socket}
  end

  def handle_event("delete_post", %{"dom_id" => dom_id}, socket) do
    # 广播删除操作到所有客户端
    Phoenix.PubSub.broadcast(PhoenixPlayground.PubSub, @topic, {:delete_post, dom_id})

    {:noreply, socket}
  end

  # 处理来自其他客户端的新帖子
  def handle_info({:new_post, post}, socket) do
    {:noreply, stream_insert(socket, :posts, post, at: 0)}
  end

  # 处理来自其他客户端的删除操作
  def handle_info({:delete_post, dom_id}, socket) do
    {:noreply, stream_delete_by_dom_id(socket, :posts, dom_id)}
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
        <div :for={{dom_id, post} <- @streams.posts} id={dom_id} class="post">
          <div class="post-content">
            <p><%= post.content %></p>
            <small><%= post.inserted_at %></small>
          </div>
          <button phx-click="delete_post" phx-value-dom_id={dom_id} class="delete-btn">Delete</button>
        </div>
      </div>
    </div>

    <style>
      .timeline { max-width: 800px; margin: 0 auto; padding: 20px; }
      .post {
        border: 1px solid #ddd;
        padding: 10px;
        margin: 10px 0;
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
      }
      .post-content { flex: 1; }
      form { margin: 20px 0; }
      textarea { width: 100%; min-height: 100px; margin-bottom: 10px; }
      button {
        padding: 8px 16px;
        background: #4a9eff;
        color: white;
        border: none;
        border-radius: 4px;
        cursor: pointer;
      }
      button:hover { background: #357abd; }
      .delete-btn {
        background: #ff4a4a;
        margin-left: 10px;
      }
      .delete-btn:hover {
        background: #bd3535;
      }
    </style>
    """
  end
end

PhoenixPlayground.start(live: TimelineLive)
