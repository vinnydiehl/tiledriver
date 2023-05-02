module Tiled
  class Sprite
    %i[path x y w h tile_x tile_y tile_w tile_h].each do |name|
      define_method name do
        instance_variable_get :"@#{name}"
      end

      define_method :"#{name}=" do |value|
        instance_variable_set :"@#{name}", value
      end
    end
  end
end
