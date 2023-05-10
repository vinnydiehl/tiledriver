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

      cache_ellipse
      cache_polygons
      cache_layers
    end

    # Changes the map and initializes a new camera.
    #
    # @param map [Tiled::Map] the map to switch to
    # @return [Tiled::Camera] the newly initialized camera
    def map=(map)
      @map = map
      @camera = Camera.new(@args, map)
    end

    # Renders a primitive onto the map, accounting for camera position.
    def render_primitive(primitive, target=:primitives)
      # TODO: Account for zoom, allow layering

      @args.outputs.send(target) << primitive.dup.tap do |p|
        p.x -= @camera.x
        p.y -= @camera.y
      end
    end

    # Renders a layer of the map.
    #
    # @param layer [Tiled::Layer || Tiled::ObjectLayer] the layer to render
    # @param target [Symbol || GTK::OutputsArray] the output target
    def render_layer(layer, target=:primitives)
      layer = map.layers[layer.to_s] unless [Layer, ObjectLayer].any? { |cls| layer.is_a? cls }
      return unless layer&.visible?

      target = @args.outputs.send(target) if target.is_a?(Symbol)

      primitives = [{ **camera.render_rect(layer.parallax), path: :"map_layer_#{layer.id}" }]

      # Re-render all animated sprites
      if layer.animated_sprites.any?
        layer_render_target(:"map_layer_#{layer.id}_animated") << layer.animated_sprites
        primitives << primitives.first.merge({ path: :"map_layer_#{layer.id}_animated" })
      end

      target << primitives
    end

    # Renders the entire map.
    #
    # @param target [Symbol || GTK::OutputsArray] the output target
    def render_map(target=:primitives)
      map.layers.each { |layer| render_layer(layer, target) }
    end
  end
end
