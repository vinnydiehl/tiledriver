class RPG
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

      @map ||= Tiled::Map.new("maps/rpg.tmx").tap(&:load)
      @renderer ||= Tiled::Renderer.new(@args, @map)
    end

    if @args.state.ticks_since_reset > 10
      if (input = @args.inputs.left_right) != 0
        @renderer.camera.move x: input * 20
      end

      if (input = @args.inputs.up_down) != 0
        @renderer.camera.move y: input * 20
      end
    end

    @renderer.render_map
  end
end
