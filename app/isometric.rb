class Isometric
  def initialize(args)
    @args = args
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

      @map ||= Tiled::Map.new("maps/isometric.tmx").tap(&:load)
      @renderer ||= Tiled::Renderer.new(@args, @map)
    end

    # Toggle player sprite
    if @args.inputs.keyboard.key_down.escape
      @player[:visible] = !@player[:visible]
    end

    # Pan camera
    if @args.state.ticks_since_reset > 10
      if (input = @args.inputs.left_right) != 0
        @renderer.camera.move x: input * 32
      end

      if (input = @args.inputs.up_down) != 0
        @renderer.camera.move y: input * 32
      end
    end

    # Zoom camera

    if @args.inputs.keyboard.key_held.q && @renderer.camera.zoom - 0.01 > 0
      @renderer.camera.zoom_out 0.01
    end

    if @args.inputs.keyboard.key_held.e
      @renderer.camera.zoom_in 0.01
    end

    @renderer.render_map

    # Uncomment for "crosshairs" to debug zoom centering
    # @args.outputs.debug << [
    #   [0, @args.grid.h / 2, @args.grid.w, @args.grid.h / 2].line,
    #   [@args.grid.w / 2, 0, @args.grid.w / 2, @args.grid.h].line
    # ]
  end
end
