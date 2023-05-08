module Tiled
  class Sprite
    def self.attr_sprite
      %i[path x y w h a r g b flip_vertically flip_horizontally angle
         tile_x tile_y tile_w tile_h source_x source_y source_w source_h
         blendmode_enum anchor_x anchor_y angle_anchor_x angle_anchor_y].each do |name|
        define_method name do
          instance_variable_get :"@#{name}"
        end

        define_method :"#{name}=" do |value|
          instance_variable_set :"@#{name}", value
        end
      end
    end
  end
end
