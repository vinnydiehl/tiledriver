require 'lib/tiled/tiled.rb'
require 'lib/tiled_renderer/tiled_renderer.rb'

require 'app/platformer.rb'

def tick(args)
  args.state.game ||= Platformer.new(args)
  args.state.game.tick
end
