module Tiled
  # Controller for a camera which moves around the map. It points to the pixel on the map
  # that is rendered to the lower-left pixel of the screen.
  class Camera
    attr_accessor :position, :zoom

    def initialize(args, map)
      @args = args
      @map = map

      @position = [map.properties[:camera_origin_x] || 0, map.properties[:camera_origin_y] || 0]
      @zoom = 1
      @zoom_offset = [0, 0]

      @screen_width = args.grid.w
      @screen_height = args.grid.h

      @map_width = @map_render_w = map.pixelwidth
      @map_height = @map_render_h = map.pixelheight

      # The camera "deadzone" around the center is actually calculated
      # as a "margin" around the edges internally.
      @margin = {}
      default = 128
      set_deadzone up: 0, down: default, left: default, right: default
    end

    def x
      position.x
    end

    def x=(value)
      position.x = value
    end

    def y
      position.y
    end

    def y=(value)
      position.y = value
    end

    def zoom_in(amount)
      @zoom += amount
    end

    def zoom_out(amount)
      @zoom -= amount
    end

    # @return [Hash] the camera-adjusted x, y, w, and h positioning of the map
    def map_xywh
      aspect_ratio = @map.pixelwidth.to_f / @map.pixelheight.to_f

      @map_render_w = (@map.pixelwidth * zoom).to_f
      @map_render_h = (@map.pixelheight * zoom).to_f

      if aspect_ratio > 1.0
        # Landscape
        @map_render_w = @map_render_h * aspect_ratio
      else
        # Portrait
        @map_render_h = @map_render_w / aspect_ratio
      end

      # Calculate the offset required to keep the camera centered, and
      # save it so we know where the outer bounds of the map are for
      # camera panning
      @zoom_offset = [
        ((@map_render_w - @map_width) * (@screen_width + (2 * position.x))) / (2 * @map_width),
        ((@map_render_h - @map_height) * (@screen_height + (2 * position.y))) / (2 * @map_height)
      ]

      {
        x: -(x + @zoom_offset.x), y: -(y + @zoom_offset.y),
        w: @map_render_w, h: @map_render_h
      }
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
        @position.x = [
          -@zoom_offset.x,
          @position.x + x,
          # (@map_render_w - ((@map_render_w * @screen_width) / @map_width))
          (@position.x + @zoom_offset.x) * (@map_width / @map_render_w)
        ].sort[1]
      end

      if y
        @position.y = [
          -@zoom_offset.y,
          @position.y + y,
          @map_height - @screen_height + @zoom_offset.y
        ].sort[1]
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
