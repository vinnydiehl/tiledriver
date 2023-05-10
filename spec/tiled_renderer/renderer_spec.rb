require "spec_helper"

def expect_output(output)
  expect_any_instance_of(OutputsArrayMock).to receive(:<<).with output
end

describe Tiled::Renderer do
  let(:args) { ArgsMock.new }
  let(:map) { Tiled::Map.new("spec/maps/test1.tmx").tap(&:load) }
  let(:renderer) { Tiled::Renderer.new args, map }

  before { allow(args).to receive(:render_target).and_return OutputsMock.new }

  context "with test1.tmx loaded" do
    describe "#map=" do
      it "changes the map" do
        old_path = renderer.map.instance_variable_get(:@path)
        renderer.map = Tiled::Map.new("spec/maps/test2.tmx").tap(&:load)

        expect(renderer.map.instance_variable_get(:@path)).not_to eq old_path
      end

      it "resets the camera" do
        renderer.camera.pan x: 10
        renderer.map = Tiled::Map.new("spec/maps/test2.tmx").tap(&:load)

        expect(renderer.camera.x).to eq 0
      end
    end

    describe "#render_primitive" do
      let(:primitive) { { x: 10, y: 10, w: 10, h: 10 } }

      %i[x y].each do |dir|
        it "subtracts the camera's #{dir} position from the primitive" do
          other = (%i[x y] - [dir]).first
          renderer.camera.pan dir => 10
          expect_any_instance_of(OutputsArrayMock).
            to receive(:<<).with({ dir => 0, other => 10, w: 10, h: 10 })

          renderer.render_primitive(primitive)
        end
      end
    end

    describe "#render_map" do
      it "renders all of the layers to args.outputs.primitives" do
        expect(renderer).to receive(:render_layer).with(
          an_instance_of(Tiled::Layer), :primitives
        ).exactly(4).times

        renderer.render_map
      end
    end
  end

  describe "an object layer" do
    let(:map) { Tiled::Map.new("spec/maps/test2.tmx").tap(&:load) }
    let(:layer) { renderer.map.layers["objects"] }

    before { allow_any_instance_of(OutputsArrayMock).to receive :<< }

    it "loads the points of the polygon" do
      expect(layer.objects.find { |o| o.object_type == :polygon }.attributes.points).
        to eq([[0, 0], [64, 32], [96, -32]])
    end

    context "when the renderer is loaded" do
      after { renderer }

      it "draws its tiles to a render target" do
        expect_output(an_object_having_attributes x: 0, y: 0, w: 64, h: 64)
      end

      it "draws its rectangles to a render target" do
        expect_output(array_including(hash_including(x: 64, y: 64, w: 64, h: 96)))
      end

      it "draws its ellipses to a render target" do
        expect_output(hash_including(x: 224, y: 0, w: 160, h: 128))
      end

      it "draws its points to a render target" do
        expect_output(hash_including(x: 59, y: 155, w: 10, h: 10))
      end

      it "draws its polygons to a render target" do
        expect_output(hash_including(x: 127, y: 127, w: 98, h: 66))
      end
    end

    describe "#render_layer" do
      after { renderer.render_layer layer }

      it "draws the layer as a map-sized sprite" do
        expect_output(array_including(hash_including(x: 0, y: 0,
          w: map.pixelwidth, h: map.pixelheight, path: :"map_layer_#{layer.id}")))
      end

      context "when the camera position has been adjusted" do
        before { renderer.camera.pan x: 50, y: 50 }

        # Verify that camera's behavior is being passed through to the
        # renderer; see camera_spec.rb for more detailed zoom specs.
        it "draws the layer as a map-sized sprite" do
          expect_output(array_including(hash_including(x: -renderer.camera.x, y: -renderer.camera.y,
                                                       w: map.pixelwidth, h: map.pixelheight,
                                                       path: :"map_layer_#{layer.id}")))
        end
      end
    end
  end
end
