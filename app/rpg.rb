SPEED = 5

class RPG
  def initialize(args)
    @args = args
    @player = {
      x: 780, y: 920, w: 32, h: 48,
      path: "sprites/square/red.png",
      visible: false
    }
  end

  def tick
    if !@renderer
      if !@loading_screen_rendered
        @args.outputs.labels << {
          text: "Loading...", x: @args.grid.w / 2, y: @args.grid.h / 2,
          size_enum: 30, alignment_enum: 1, vertical_alignment_enum: 1
        }
        @loading_screen_rendered = true
        return
      end

      @map ||= Tiled::Map.new("maps/rpg.tmx").tap(&:load)
      @renderer ||= Tiled::Renderer.new(@args, @map)
    end

    # Toggle player sprite
    if @args.inputs.keyboard.key_down.escape
      @player[:visible] = !@player[:visible]
    end

    if @player[:visible]
      # Move player sprite
      if @args.state.ticks_since_reset > 10
        if (input = @args.inputs.left_right) != 0
          @player[:x] += input * SPEED
        end

        if (input = @args.inputs.up_down) != 0
          @player[:y] += input * SPEED
        end
      end

      @renderer.camera.track @player
    else
      # Pan camera
      if @args.state.ticks_since_reset > 10
        if (input = @args.inputs.left_right) != 0
          @renderer.camera.move x: input * 20
        end

        if (input = @args.inputs.up_down) != 0
          @renderer.camera.move y: input * 20
        end
      end
    end

    # Zoom camera

    if @args.inputs.keyboard.key_held.q
      @renderer.camera.zoom_out 0.01
    end

    if @args.inputs.keyboard.key_held.e
      @renderer.camera.zoom_in 0.01
    end

    @renderer.render_map(sprites: @player[:visible] ? @player : nil)
  end
end
