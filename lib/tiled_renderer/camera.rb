module Tiled
  # Controller for a camera which moves around the map. It points to the pixel on the map
  # that is rendered to the lower-left pixel of the screen.
  class Camera
    attr_accessor :position

    def initialize(args, map)
      @args = args
      @map = map

      @position = [map.properties[:camera_origin_x] || 0, map.properties[:camera_origin_y] || 0]

      @screen_width = args.grid.w
      @screen_height = args.grid.h

      # The camera "deadzone" around the center is actually calculated
      # as a "margin" around the edges internally.
      @margin = {}
      default = 128
      set_deadzone up: 0, down: default, left: default, right: default
    end

    def x
      position.x
    end

    def y
      position.y
    end

    def set_deadzone(up: nil, down: nil, left: nil, right: nil)
      { @screen_height => %i[up down], @screen_width => %i[left right] }.each do |size, dirs|
        midpoint = size / 2.0

        dirs.each do |dir|
          value = instance_eval(dir.to_s)
          if value
            @margin[dir] = midpoint - value
          end
        end
      end
    end

    def move(x: nil, y: nil)
      if x
        @position.x = [0, @position.x + x, (@map.width * @map.tilewidth) - @screen_width].sort[1]
      end

      if y
        @position.y = [0, @position.y + y, (@map.height * @map.tileheight) - @screen_height].sort[1]
      end
    end

    def track(rect)
      x, y, w, h = rect.is_a?(Hash) ? [rect.x, rect.y, rect.w, rect.h] : rect

      screen_position = [x - @position.x, y - @position.y]
      opposite = [screen_position.x + w, screen_position.y + h]

      right_x = @screen_width - @margin[:right]
      if opposite.x > right_x
        move x: opposite.x - right_x
      elsif screen_position.x < @margin[:left]
        move x: screen_position.x - @margin[:left]
      end

      top_y = @screen_height - @margin[:up]
      if opposite.y > top_y
        move y: opposite.y - top_y
      elsif screen_position.y < @margin[:down]
        move y: screen_position.y - @margin[:down]
      end
    end
  end
end
