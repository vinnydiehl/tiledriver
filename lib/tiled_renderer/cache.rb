module Tiled
  # Internal functions for managing cached assets.
  class Renderer
    private

    # Given a target name, returns a render target the size of the map. If the
    # target exists already, it will be cleared.
    #
    # @param target_name [Symbol] the name of the render target to create
    # @return [GTK::OutputsArray] the primitives input for the render target
    def layer_render_target(target_name)
      target = @args.render_target(target_name).tap do |t|
        t.clear_before_render = true
        t.width = @map.width * @map.tilewidth
        t.height = @map.height * @map.tileheight
      end.primitives
    end

    # Saves a circle to the `:ellipse` render target. We'll use this for
    # displaying ellipse objects.
    def cache_ellipse
      # Draw a circle by iterating over the DIAMETER and drawing a bunch
      # of lines that get wider as they reach the center.
      DIAMETER.times do |i|
        height = i - RADIUS
        length = Math.sqrt((RADIUS * RADIUS) - (height * height))
        @args.render_target(:ellipse).lines << {
          x: i, y: RADIUS - length, x2: i, y2: RADIUS + length,
          r: 255, g: 255, b: 255
        }
      end
    end

    # Draws all of the polygons on the map to render targets with names in the
    # format of e.g. :polygon1, :polygon2, etc. using the object's ID.
    def cache_polygons
      map.layers.select { |l| l.is_a? ObjectLayer }.each do |layer|
        layer.objects.select { |o| o.object_type == :polygon }.each do |object|
          # Each polygon is cached to its own render target
          target = @args.render_target(:"polygon#{object.id}").lines

          # The points on the polygon can go below zero, but we can't render to pixel < 0
          # on a render target. We'll need these to calculate some offsets
          min_x = object.points.map(&:x).min
          min_y = object.points.map(&:y).min

          # Calculate the starting point of the polygon
          offset = [(object.points[0].x * 2) - min_x + 1, (object.points[0].y * 2) - min_y + 1]

          # Similar to the circle, this is drawn as a bunch of horizontal lines
          object.height.to_i.times do |y|
            # We need to get the intersections where a horizontal line
            # across the screen crosses the edges of the polygon
            intersections = []

            y += min_y

            object.points.each_with_index do |point, index|
              next_point = object.points[(index + 1) % object.points.length]

              # We're iterating over each line of the polygon. This if statement
              # will hit on each line that intersects the line that we're drawing
              if (point.y <= y && next_point.y > y) || (next_point.y <= y && point.y > y)
                intersections <<
                  if point.y == next_point.y
                    # The edge is horizontal, so the intersection is just the
                    # X-coordinate of the point
                    (offset.x + point.x)
                  else
                    # Find the X-coordinate where the edge intersects the
                    # row using the equation of the line
                    (offset.x +
                      ((y - point.y) * (next_point.x - point.x) /
                      (next_point.y - point.y)) +
                     point.x)
                  end
              end
            end

            # Y-coordinate on the sprite that this line is being drawn
            sprite_y = offset.y + y

            # `intersections` contains every X coordinate where the line that we're drawing
            # crosses the border of the shape we need to draw. In cases like a triangle, there
            # will only be 2 intersections and we can just draw the line between them. But for
            # more complex shapes where there e.g. a bunch of vertical spikes, we will have an
            # (always evenly sized) array that we will need to sort and then iterate over
            # 2 at a time, drawing lines between each slice of 2.
            intersections.sort! if intersections.size > 2

            i = 0
            while i < intersections.length - 1
              target << {
                x: intersections[i], y: sprite_y,
                x2: intersections[i + 1], y2: sprite_y,
                **layer.color.to_h, a: layer.color.a * 0.7
              }
              i += 2
            end
          end

          # Draw the outline connecting each point
          object.points.each_with_index do |point, index|
            next_point = object.points[(index + 1) % object.points.length]

            target << {
              x: offset.x + point.x, y: offset.y + point.y,
              x2: offset.x + next_point.x, y2: offset.y + next_point.y,
              **layer.color.to_h
            }
          end
        end
      end
    end

    def cache_layers
      @map.layers.each do |layer|
        render_target = layer_render_target(:"map_layer_#{layer.id}")

        case layer
        when Layer
          render_target << layer.sprites
        when ObjectLayer
          layer.objects.each do |object|
            color = layer.color.to_h
            a = color[:a] * 0.7

            case object.object_type
            when :tile
              render_target << Sprite.from_tiled(map.find_tile(object.gid),
                x: object.x, y: object.y, w: object.width, h: object.height)
            when :rectangle
              border = {
                primitive_marker: :border,
                x: object.x, y: object.y,
                w: object.width, h: object.height,
                **color
              }
              solid = border.merge(primitive_marker: :solid, a: color[:a] * 0.7)

              render_target << [border, solid]
            when :ellipse
              render_target << {
                x: object.x, y: object.y,
                w: object.width, h: object.height,
                path: :ellipse,
                source_x: 0, source_y: 0,
                source_w: DIAMETER, source_h: DIAMETER,
                **color, a: a
              }
            when :polygon
              render_target << {
                x: object.x - (object.points[0].x - object.points.map(&:x).min) - 1,
                y: object.y - (object.points[0].y - object.points.map(&:y).min) + object.height - 1,
                w: object.width, h: object.height,
                path: :"polygon#{object.id}",
                source_x: 0, source_y: 0,
                source_w: object.width, source_h: object.height,
                **color
              }
            when :point
              size = 10
              render_target << {
                x: object.x - (size / 2.0), y: object.y - (size / 2.0),
                w: size, h: size,
                path: :ellipse,
                source_x: 0, source_y: 0,
                source_w: DIAMETER, source_h: DIAMETER,
                **color
              }
            end
          end
        end
      end
    end
  end
end
