require "spec_helper"

def expect_output(output)
  expect_any_instance_of(OutputsArrayMock).to receive(:<<).with output
end

describe Tiled::Renderer do
  let(:args) { ArgsMock.new }
  let(:renderer) { Tiled::Renderer.new args, Tiled::Map.new("spec/maps/test1.tmx").tap(&:load) }

  before do
    allow(args).to receive(:render_target).and_return OutputsMock.new
  end

  context "with test1.tmx loaded" do
    describe "#map=" do
      it "changes the map" do
        old_path = renderer.map.instance_variable_get(:@path)
        renderer.map = Tiled::Map.new("spec/maps/test2.tmx").tap(&:load)

        expect(renderer.map.instance_variable_get(:@path)).not_to eq old_path
      end

      it "resets the camera" do
        renderer.camera.move x: 10
        renderer.map = Tiled::Map.new("spec/maps/test2.tmx").tap(&:load)

        expect(renderer.camera.x).to eq 0
      end
    end

    describe "#render_primitive" do
      let(:primitive) { { x: 10, y: 10, w: 10, h: 10 } }

      %i[x y].each do |dir|
        it "subtracts the camera's #{dir} position from the primitive" do
          other = (%i[x y] - [dir]).first
          renderer.camera.move dir => 10
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
    before do
      renderer.map = Tiled::Map.new("spec/maps/test2.tmx").tap(&:load)
    end

    let(:layer) { renderer.map.layers["objects"] }

    it "loads the points of the polygon" do
      expect(layer.objects.find { |o| o.object_type == :polygon }.attributes.points).
        to eq([[0, 0], [64, 32], [96, -32]])
    end

    describe "#render_layer" do
      context "when rendering an object layer" do
        before { allow_any_instance_of(OutputsArrayMock).to receive :<< }
        after { renderer.render_layer layer }

        it "renders the tile" do
          expect_output(an_object_having_attributes x: 0, y: 0, w: 64, h: 64)
        end

        it "renders the rectangle" do
          expect_output(array_including(hash_including(x: 64, y: 64, w: 64, h: 96)))
        end

        it "renders the ellipse" do
          expect_output(hash_including(x: 224, y: 0, w: 160, h: 128))
        end

        it "renders the point" do
          expect_output(hash_including(x: 59, y: 155, w: 10, h: 10))
        end

        it "renders the polygon" do
          expect_output(hash_including(x: 127, y: 127, w: 98, h: 66))
        end
      end
    end
  end
end
