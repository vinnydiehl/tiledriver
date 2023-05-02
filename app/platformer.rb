class Platformer
  def initialize(args)
    @args = args
    @map = Tiled::Map.new("maps/platformer.tmx").tap(&:load)
    @renderer = Tiled::Renderer.new(args, @map)
    @player = {
      x: 96, y: 64, w: 40, h: 40,
      path: "sprites/square/red.png"
    }
  end

  def tick
    if (input = @args.inputs.left_right) != 0
      @player[:x] += input * 10

      # Fake collision handling ;)
      @player[:x] = [64, @player[:x], ((@map.width - 2) * @map.tilewidth) - @player[:w]].sort[1]
    end

    @renderer.camera.track(@player)
    @renderer.render_map
    @renderer.render_primitive(@player)
  end
end
