require "lib/tiled/tiled.rb"
require "lib/tiledriver/tiledriver.rb"

require "app/platformer.rb"
require "app/rpg.rb"
require "app/isometric.rb"

SAMPLE_APPS = %i[Platformer RPG Isometric]

def tick(args)
  args.state.selected_game ||= 0
  args.state.ticks_since_reset ||= 0

  game = args.state.selected_game
  if args.inputs.keyboard.key_down.right
    args.state.selected_game = (args.state.selected_game + 1) % SAMPLE_APPS.size
  elsif args.inputs.keyboard.key_down.left
    args.state.selected_game = (args.state.selected_game - 1) % SAMPLE_APPS.size
  end

  if game != args.state.selected_game || !args.state.game
    args.state.game = Object::const_get(SAMPLE_APPS[args.state.selected_game]).new(args)
    args.state.ticks_since_reset = 0
  end

  args.state.game.tick
  args.state.ticks_since_reset += 1
end
