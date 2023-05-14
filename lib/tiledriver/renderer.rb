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

    # Renders a layer of the map, accounting for the camera.
    #
    # @param layer [Tiled::Layer || Tiled::ObjectLayer] the layer to render
    # @option :target [Symbol || GTK::OutputsArray] the output target
    def render_layer(layer, target: :primitives)
      layer = map.layers[layer.to_s] unless [Layer, ObjectLayer].any? { |cls| layer.is_a? cls }
      return unless layer&.visible?

      target = get_target(target)

      primitives = [{ **camera.render_rect(layer.parallax), path: :"map_layer_#{layer.id}" }]

      # Re-render all animated sprites
      if layer.animated_sprites.any?
        layer_render_target(:"map_layer_#{layer.id}_animated") << layer.animated_sprites
        primitives << primitives.first.merge({ path: :"map_layer_#{layer.id}_animated" })
      end

      target << primitives
    end

    # Pass in a bunch of sprites with their `x` and `y` values set to their map
    # coordinates, and this method will render them to the screen accounting for
    # the camera.
    #
    # @param sprites [Hash || Array] sprite(s) to render
    # @option :target [Symbol || GTK::OutputsArray] the output target
    def render_sprite_layer(sprites, target: :primitives)
      target = get_target(target)
      sprites = [sprites] unless sprites.is_a?(Array)

      layer_render_target(:"tiledriver_sprites") << sprites
      target << { **camera.render_rect, path: :"tiledriver_sprites" }
    end

    # Renders the entire map, optionally with external sprites baked into it, accounting
    # for the camera.
    #
    # @option :target [Symbol || GTK::OutputsArray] the output target
    # @option :sprites [Hash || Array] sprite(s) to render on top of this layer
    # @option :depth [Integer] how many layers deep to render the sprites
    def render_map(target: :primitives, sprites: nil, depth: 1)
      if sprites
        if map.layers.count > 1
          map.layers.at(0..(-depth - 1)).each { |layer| render_layer(layer, target: target) }
          render_sprite_layer sprites, target: target
          map.layers.at((-depth)..-1).each { |layer| render_layer(layer, target: target) } unless depth == 0
        elsif map.layers.count == 1
          render_layer layers.first, target: target if depth < 1
          render_sprite_layer sprites, target: target
          render_layer layers.first, target: target if depth >= 1
        else
          render_sprite_layer sprites, target: target
        end
      else
        map.layers.each { |layer| render_layer(layer, target: target) }
      end
    end

    private

    # For methods that can take a Symbol and translate it to an outputs target, e.g.
    # `:primitives` -> `@args.outputs.primitives`. Returns the input back otherwise.
    #
    # @param target [Symbol || GTK::OutputsArray] a symbol naming the desired output target
    # @return [GTK::OutputsArray] the output target
    def get_target(target)
      target.is_a?(Symbol) ? @args.outputs.send(target) : target
    end
  end
end
