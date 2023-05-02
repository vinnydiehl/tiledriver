module Tiled
  # Resolution of circle sprite used to make ellipses
  RADIUS = 300
  DIAMETER = 2 * RADIUS

  # Encapsulates a `Map` and a `Camera`. Contains methods to render a map or individual
  # layers with respect to the camera, and track external primitives with the camera.
  class Renderer
    attr_reader :map, :camera

    def initialize(args, map)
      @args = args
      @map = map

      @camera = Camera.new(args, map)

      @screen_width = args.grid.w
      @screen_height = args.grid.h

      # Draw a circle by iterating over the DIAMETER and drawing a bunch
      # of lines that get wider as they reach the center. We'll use this
      # sprite for displaying ellipse objects.
      DIAMETER.times do |i|
        height = i - RADIUS
        length = Math.sqrt((RADIUS * RADIUS) - (height * height))
        @args.render_target(:ellipse).lines << {
          x: i, y: RADIUS - length, x2: i, y2: RADIUS + length,
          r: 255, g: 255, b: 255
        }
      end

      # Draw all polygon objects to render targets
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

    def map=(map)
      @map = map
      @camera = Camera.new(@args, map)
    end

    def render_primitive(primitive, target=:primitives)
      @args.outputs.send(target) << primitive.dup.tap do |p|
        p.x -= @camera.x
        p.y -= @camera.y
      end
    end

    def render_layer(layer, target=:primitives)
      layer = map.layers[layer.to_s] unless [Layer, ObjectLayer].any? { |cls| layer.is_a? cls }
      return unless layer&.visible?

      stream = target.is_a?(Symbol) ? @args.outputs.send(target) : target

      layer_camera = [@camera.x * layer.parallax.x, @camera.y, layer.parallax.y]

      case layer
      when Layer
        stream << layer.sprites.map do |sprite|
          sprite.dup.tap do |s|
            s.x -= layer_camera.x
            s.y -= layer_camera.y
          end
        end
      when ObjectLayer
        layer.objects.each do |object|
          color = layer.color.to_h
          a = color[:a] * 0.7

          x = object.x - layer_camera.x
          y = object.y - layer_camera.y

          case object.object_type
          when :tile
            stream << Sprite.from_tiled(map.find_tile(object.gid),
                                        x: x, y: y, w: object.width, h: object.height)
          when :rectangle
            border = {
              primitive_marker: :border,
              x: x, y: y,
              w: object.width, h: object.height,
              **color
            }
            solid = border.merge(primitive_marker: :solid, a: color[:a] * 0.7)

            stream << [border, solid]
          when :ellipse
            stream << {
              x: x, y: y,
              w: object.width, h: object.height,
              path: :ellipse,
              source_x: 0, source_y: 0,
              source_w: DIAMETER, source_h: DIAMETER,
              **color, a: a
            }
          when :polygon
            stream << {
              x: x - (object.points[0].x - object.points.map(&:x).min) - 1,
              y: y - (object.points[0].y - object.points.map(&:y).min) + object.height - 1,
              w: object.width, h: object.height,
              path: :"polygon#{object.id}",
              source_x: 0, source_y: 0,
              source_w: object.width, source_h: object.height,
              **color
            }
          when :point
            size = 10
            stream << {
              x: x - (size / 2.0), y: y - (size / 2.0),
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

    def render_map(target=:primitives)
      map.layers.each { |layer| render_layer(layer, target) }
    end
  end
end
