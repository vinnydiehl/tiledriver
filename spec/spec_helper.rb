require "active_support/core_ext/hash"
require "active_support/isolated_execution_state"
require "active_support/xml_mini"

# Stub to get Tiled::Sprite to load
def attr_sprite
  nil
end

# Need to load the modules first
preload = %w[attribute_assignment serializable utils with_attributes
             sprite animated_sprite]
preload.each { |m| require_relative "../lib/tiled/#{m}" }

Dir["lib/**/*.rb"].each do |file|
  # Load everything except the base files and modules
  unless (["tiled.rb", "tiled_renderer.rb"] + preload).any? { |m| file.include? m }
    file = file[0...-3]
    require_relative "../#{file}"
  end
end

require_relative "constants"

require_relative "core_ext"
require_relative "mocks"
require_relative "tiled_patch"

RSpec.configure do |config|
  # Add `focus: true` hash parameter to a describe/context/it block
  # to only run the specs in that block
  config.filter_run_when_matching :focus

  # More verbose output if only running one spec
  config.default_formatter = "doc" if config.files_to_run.one?

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, fix the order by providing the seed,
  # which is printed after each run, e.g. --seed 1234
  config.order = :random
  Kernel.srand config.seed
end
