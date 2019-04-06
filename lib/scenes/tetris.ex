defmodule TetrisScenic.Scene.Tetris do
  use Scenic.Scene
  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives, only: [rect: 3]

  @graph Graph.build(font: :roboto, font_size: 36)
  @frame_ms 500
  @vp_width  500 #TODO hmmmmm!
  @tetriminos [
    [
      %{
        x: @vp_width / 2,
        y: 0,
        size: @vp_width / 10,
        color: :red
      },
      %{
        x: @vp_width / 2 - @vp_width / 10,
        y: 0,
        size: @vp_width / 10,
        color: :red
      },
      %{
        x: @vp_width / 2 + @vp_width / 10,
        y: 0,
        size: @vp_width / 10,
        color: :red
      },
      %{
        x: @vp_width / 2 + 2 * (@vp_width / 10),
        y: 0,
        size: @vp_width / 10,
        color: :red
      }
    ],
    [
      %{
        x: @vp_width / 2,
        y: -@vp_width / 10,
        size: @vp_width / 10,
        color: :green
      },
          %{
            x: @vp_width / 2 - @vp_width / 10,
            y: -@vp_width / 10,
            size: @vp_width / 10,
            color: :green
          },
          %{
            x: @vp_width / 2 + @vp_width / 10,
            y: 0,
            size: @vp_width / 10,
            color: :green
          },
      %{
        x: @vp_width / 2,
        y: 0,
        size: @vp_width / 10,
        color: :green
      }
    ],
    [
      %{
        x: @vp_width / 2,
        y: 0,
        size: @vp_width / 10,
        color: :yellow
      },
      %{
        x: @vp_width / 2 - @vp_width / 10,
        y: 0,
        size: @vp_width / 10,
        color: :yellow
      },
      %{
        x: @vp_width / 2 + @vp_width / 10,
        y: 0,
        size: @vp_width / 10,
        color: :yellow
      },
      %{
        x: @vp_width / 2 - (@vp_width / 10),
        y: -@vp_width / 10,
        size: @vp_width / 10,
        color: :yellow
      }
    ],
    [
      %{
        x: @vp_width / 2,
        y: 0,
        size: @vp_width / 10,
        color: :orange
      },
      %{
        x: @vp_width / 2 - @vp_width / 10,
        y: 0,
        size: @vp_width / 10,
        color: :orange
      },
      %{
        x: @vp_width / 2 + @vp_width / 10,
        y: 0,
        size: @vp_width / 10,
        color: :orange
      },
      %{
        x: @vp_width / 2 + (@vp_width / 10),
        y: -@vp_width / 10,
        size: @vp_width / 10,
        color: :orange
      }
    ],
    [
      %{
        x: @vp_width / 2,
        y: -@vp_width / 10,
        size: @vp_width / 10,
        color: :blue
      },
      %{
        x: @vp_width / 2 + @vp_width / 10,
        y: -@vp_width / 10,
        size: @vp_width / 10,
        color: :blue
      },
      %{
        x: @vp_width / 2 + @vp_width / 10,
        y: 0,
        size: @vp_width / 10,
        color: :blue
      },
      %{
        x: @vp_width / 2,
        y: 0,
        size: @vp_width / 10,
        color: :blue
      }
    ],
    [
      %{
        x: @vp_width / 2 + @vp_width /10,
        y: -@vp_width / 10,
        size: @vp_width / 10,
        color: :purple
      },
      %{
        x: @vp_width / 2 + (2 * @vp_width / 10),
        y: -@vp_width / 10,
        size: @vp_width / 10,
        color: :purple
      },
      %{
        x: @vp_width / 2 + @vp_width / 10,
        y: 0,
        size: @vp_width / 10,
        color: :purple
      },
      %{
        x: @vp_width / 2,
        y: 0,
        size: @vp_width / 10,
        color: :purple
      }
    ],
    [
      %{
        x: @vp_width / 2,
        y: -@vp_width / 10,
        size: @vp_width / 10,
        color: :pink
      },
      %{
        x: @vp_width / 2 - @vp_width / 10,
        y: 0,
        size: @vp_width / 10,
        color: :pink
      },
      %{
        x: @vp_width / 2 + @vp_width / 10,
        y: 0,
        size: @vp_width / 10,
        color: :pink
      },
      %{
        x: @vp_width / 2,
        y: 0,
        size: @vp_width / 10,
        color: :pink
      }
    ]

  ]

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
      moving_blocks: Enum.random(@tetriminos),
      blocks: []
    }

    graph = state.graph
            |> draw_blocks(state.blocks)
            |> draw_blocks(state.moving_blocks)

    {:ok, state, push: graph}
  end


  defp draw_blocks(graph, blocks) do
    Enum.reduce(blocks, graph, fn block, graph -> draw_block(graph, block) end)
  end

  defp draw_block(graph, block) do
    graph
    |> rect({block.size, block.size}, fill: block.color, translate: {block.x, block.y})
  end

  def handle_info(:frame, %{frame_count: frame_count} = state) do
    new_state = state
                |> move_block
                |> delete_full_row

    graph = new_state.graph
            |> draw_blocks(new_state.blocks)
            |> draw_blocks(new_state.moving_blocks)

    {:noreply, %{new_state | frame_count: frame_count + 1}, push: graph}
  end

  defp delete_full_row(state) do

    blocks_to_delete = state.blocks
                       |> Enum.group_by(&(&1.y))
                       |> Enum.map(fn {_key, list} -> list end)
                       |> Enum.filter(&(length(&1) == 10))
                       |> Enum.flat_map(&(&1))

    if length(blocks_to_delete) > 0 do
      new_blocks =
        state.blocks
        |> Enum.filter(&(!Enum.member?(blocks_to_delete, &1)))
        |> Enum.map(&(conditionally_move_down(&1, hd(blocks_to_delete))))
      put_in(state, [:blocks], new_blocks)
    else
      state
    end

  end

  defp conditionally_move_down(block_to_move, deleted_block) do
    if block_to_move.y < deleted_block.y do
      put_in(block_to_move, [:y], block_to_move.y + block_to_move.size)
    else
      block_to_move
    end
  end

  defp move_block(state) do
    new_state = put_in(state, [:moving_blocks], moved_tetrimino(state))
    cond do
      any_stop?(new_state) ->
        state
        |> put_in([:blocks], (state.moving_blocks ++ state.blocks))
        |> put_in(
             [:moving_blocks],
             Enum.random(@tetriminos)
           )
      true ->
        new_state
    end
  end

  defp moved_tetrimino(state) do
    Enum.map(state.moving_blocks, &(put_in(&1, [:y], &1.y + &1.size)))
  end

  defp any_stop?(state) do
    !(state.moving_blocks
      |> Stream.filter(&(stop?(state, &1)))
      |> Enum.empty?)
  end

  defp stop?(state, block) do
    block.y + block.size > state.board_height || block.x >= state.board_width || block.x < 0 || block_on_same_x_y?(
      state,
      block
    )
  end

  def handle_input({:key, {"left", :press, _}}, _context, state) do
    new_state = move_sideways(state, fn x -> x - state.board_width / 10 end)
                |> delete_full_row
    graph = new_state.graph
            |> draw_blocks(state.blocks)
            |> draw_blocks(state.moving_blocks)
    {:noreply, new_state, push: graph}
  end

  def handle_input({:key, {"right", :press, _}}, _context, state) do
    new_state = move_sideways(state, fn x -> x + state.board_width / 10 end)
                |> delete_full_row
    graph = new_state.graph
            |> draw_blocks(state.blocks)
            |> draw_blocks(state.moving_blocks)
    {:noreply, new_state, push: graph}  end

  def handle_input({:key, {"down", :press, _}}, _context, state) do
    new_state = move_block(state)
                |> delete_full_row
    graph = new_state.graph
            |> draw_blocks(state.blocks)
            |> draw_blocks(state.moving_blocks)
    {:noreply, new_state, push: graph}
  end

  def handle_input(_input, _context, state), do: {:noreply, state}

  defp move_sideways(state, position_func) do

    new_state = put_in(
      state,
      [:moving_blocks],
      Enum.map(state.moving_blocks, &(put_in(&1, [:x], position_func.(&1.x))))
    )

    cond do
      !any_stop?(new_state) ->
        new_state
      true ->
        state
    end
  end

  defp block_on_same_x_y?(state, block) do
    Enum.member?(
      state.blocks
      |> Stream.filter(&(&1.y == block.y))
      |> Stream.map(fn e -> e.x end),
      block.x
    )
  end

end
