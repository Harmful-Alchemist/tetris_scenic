defmodule TetrisScenic.Scene.Tetris do
  use Scenic.Scene
  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives, only: [rect: 3, text: 3]

  @graph Graph.build(font: :roboto, font_size: 36)
  @frame_ms 500

  def init(_args, opts) do

    viewport = opts[:viewport]

    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(viewport)

    {:ok, timer} = :timer.send_interval(@frame_ms, :frame)

    state = %{
      graph: @graph,
      frame_count: 1,
      frame_timer: timer,
      board_height: vp_height,
      board_width: vp_width,
      moving_block: %{
        x: vp_width / 2,
        y: 0,
        size: vp_width / 10
      },
      blocks: []
    }

    graph = state.graph
            |> draw_blocks(state.blocks)
            |> draw_block(state.moving_block)

    {:ok, state, push: graph}
  end


  defp draw_blocks(graph, blocks) do
    Enum.reduce(blocks, graph, fn block, graph -> draw_block(graph, block) end)
  end

  defp draw_block(graph, block) do
    graph
    |> rect({block.size, block.size}, fill: :red, translate: {block.x, block.y})
  end

  def handle_info(:frame, %{frame_count: frame_count} = state) do
    state = move_block(state)

    graph = state.graph
            |> draw_blocks(state.blocks)
            |> draw_block(state.moving_block)

    {:noreply, %{state | frame_count: frame_count + 1}, push: graph}
  end

  defp move_block(state) do
    block_size = state.moving_block.size
    new_pos = min(state.moving_block.y + block_size, state.board_height - block_size)

    cond do
      stop?(state, new_pos, block_size) ->
        state
        |> put_in([:blocks], [put_in(state.moving_block, [:y], new_pos) | state.blocks])
        |> put_in(
             [:moving_block],
             %{
               x: state.board_width / 2,
               y: 0,
               size: state.board_width / 10
             }
           )
      true ->
        state
        |> put_in([:moving_block, :y], new_pos)
    end
  end

  defp stop?(state, new_pos, block_size) do
    new_pos >= state.board_height - block_size || !(
      state.blocks
      |> Stream.filter(&(&1.y == new_pos + block_size))
      |> Stream.filter(&(&1.x == state.moving_block.x))
      |> Enum.empty?)
  end

  def handle_input({:key, {"left", :press, _}}, _context, state) do
    new_state = move_block(state, state.moving_block.x - state.board_width / 10)
    graph = new_state.graph
            |> draw_blocks(state.blocks)
            |> draw_block(state.moving_block)
    {:noreply, new_state, push: graph}
  end

  def handle_input({:key, {"right", :press, _}}, _context, state) do
    new_state = move_block(state, state.moving_block.x + state.board_width / 10)
    graph = new_state.graph
            |> draw_blocks(state.blocks)
            |> draw_block(state.moving_block)
    {:noreply, new_state, push: graph}  end

  def handle_input({:key, {"down", :press, _}}, _context, state) do
    #    cond do
    #      state.moving_block.y < state.board_height ->
    new_state = move_block(state)
    graph = new_state.graph
            |> draw_blocks(state.blocks)
            |> draw_block(state.moving_block)
    {:noreply, new_state, push: graph}
    #      true ->
    #        {:noreply, state}
    #    end
  end

  def handle_input(_input, _context, state), do: {:noreply, state}

  defp move_block(state, pos) do
    cond do
      pos < state.board_width && pos >= 0 && state.blocks
                                             |> Stream.filter(&(&1.y == state.moving_block.y))
                                             |> Stream.filter(&(&1.x == pos))
                                             |> Enum.empty?
      ->
        put_in(state, [:moving_block, :x], pos)
      true ->
        state
    end
  end

end
