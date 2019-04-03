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
    new_state = state
                |> move_block
                |> delete_full_row

    graph = new_state.graph
            |> draw_blocks(new_state.blocks)
            |> draw_block(new_state.moving_block)

    {:noreply, %{new_state | frame_count: frame_count + 1}, push: graph}
  end

  defp delete_full_row(state) do

    new_blocks =
      state.blocks
      |> Enum.group_by(&(&1.y))
      |> Enum.map(fn {key, list} -> list end)
      |> Enum.filter(&(length(&1) != 10))
      |> Enum.flat_map(&(&1))

    new_state = put_in(state, [:blocks], new_blocks)
    cond do
      length(new_blocks) < length(state.blocks) ->
        new_blocks
        |> Enum.sort_by(&(&1.y))
        |> Enum.reverse
        |> move_down(new_state)
      true ->
        state
    end

  end

  defp move_down([block | tail], state) do
    new_state = put_in(state, [:blocks], List.delete(state.blocks, block))

    blocks_below = Enum.filter(new_state.blocks, &(&1.x == block.x))

    new_state = cond do
      !(blocks_below |> Enum.empty?) ->
        highest_block = blocks_below
                        |> Enum.sort_by(&(&1.y))
                        |> hd
        put_in(new_state, [:blocks], [put_in(block, [:y], highest_block.y + block.size) | new_state.blocks])
#      block.y >= state.board_height - block.size ->
#        put_in(new_state, [:blocks], [put_in(block, [:y], state.board_height - block.size) | new_state.blocks])
      true ->
        put_in(new_state, [:blocks], [put_in(block, [:y], state.board_height - block.size) | new_state.blocks])


    end
    move_down(tail, new_state)
  end

  defp move_down([], state) do
    state
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
    new_state = move_block(state, state.moving_block.x - state.board_width / 10) |> delete_full_row
    graph = new_state.graph
            |> draw_blocks(state.blocks)
            |> draw_block(state.moving_block)
    {:noreply, new_state, push: graph}
  end

  def handle_input({:key, {"right", :press, _}}, _context, state) do
    new_state = move_block(state, state.moving_block.x + state.board_width / 10) |> delete_full_row
    graph = new_state.graph
            |> draw_blocks(state.blocks)
            |> draw_block(state.moving_block)
    {:noreply, new_state, push: graph}  end

  def handle_input({:key, {"down", :press, _}}, _context, state) do
    new_state = move_block(state) |> delete_full_row
    graph = new_state.graph
            |> draw_blocks(state.blocks)
            |> draw_block(state.moving_block)
    {:noreply, new_state, push: graph}
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
