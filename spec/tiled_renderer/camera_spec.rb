require "spec_helper"

# 32x32 sprite
TGT_SIZE = 32

# Deadzone data
DZ_DEFAULT = 128
DZ_MAX = {
  left: DZ_DEFAULT,
  right: DZ_DEFAULT - TGT_SIZE,
  down: DZ_DEFAULT - TGT_SIZE
}.freeze

class TrackTarget
  attr_accessor :x, :y
  attr_reader :w, :h

  def initialize
    @x = SCREEN_WIDTH / 2
    @y = SCREEN_HEIGHT / 2
    @w = TGT_SIZE
    @h = TGT_SIZE
  end

  def move(x_offset, y_offset)
    @x += x_offset
    @y += y_offset
  end

  def rect
    [x, y, w, h]
  end

  def primitive
    {
      x: x, y: y, w: w, h: h,
      path: "foo/bar"
    }
  end
end

describe Tiled::Camera do
  let(:args) { ArgsMock.new }
  let(:map) { Tiled::Map.new("spec/maps/test1.tmx").tap(&:load) }
  let(:camera) { Tiled::Camera.new args, map }

  it "starts at x=0" do
    expect(camera.x).to eq 0
  end

  it "starts at y=0" do
    expect(camera.y).to eq 0
  end

  describe "#pan" do
    {
      up:   [:y,  50],
      down: [:y, -50],
      left: [:x, -50],
      right: [:x, 50]
    }.each do |dir, vector|
      axis, distance = vector
      it "moves the camera #{dir}" do
        orig_position = [50, 75]
        camera.position = orig_position.dup
        camera.pan(axis => distance)

        expect(camera.send axis).to eq(orig_position.send(axis) + distance)
      end
    end
  end

  describe "#track" do
    subject { TrackTarget.new }
    let(:camera_origin) { [200, 200] }

    before do
      camera.pan x: camera_origin.x, y: camera_origin.y
      # Keep target in middle of screen (right up against top of deadzone)
      subject.move(camera_origin.x, camera_origin.y - 32)
    end

    it "has a deadzone to the left" do
      subject.x -= DZ_MAX[:left]
      camera.track subject.rect

      expect(camera.position).to eq camera_origin
    end

    it "has a deadzone to the right" do
      subject.x += DZ_MAX[:right]
      camera.track subject.rect

      expect(camera.position).to eq camera_origin
    end

    it "has a deadzone to the bottom" do
      subject.y -= 96
      camera.track subject.rect

      expect(camera.position).to eq camera_origin
    end

    it "scrolls up if you push past the top deadzone" do
      subject.y += 1
      camera.track subject.rect

      expect(camera.position).to eq(camera_origin.tap { |c| c.y += 1 })
    end

    it "scrolls left if you push past the left deadzone" do
      subject.x -= DZ_MAX[:left] + 1
      camera.track subject.rect

      expect(camera.position).to eq(camera_origin.tap { |c| c.x -= 1 })
    end

    it "scrolls right if you push past the right deadzone" do
      subject.x += DZ_MAX[:right] + 1
      camera.track subject.rect

      expect(camera.position).to eq(camera_origin.tap { |c| c.x += 1 })
    end

    it "scrolls down if you push past the bottom deadzone" do
      subject.y -= DZ_MAX[:down] + 1
      camera.track subject.rect

      expect(camera.position).to eq(camera_origin.tap { |c| c.y -= 1 })
    end

    describe "the deadzone" do
      let(:adjustment) { 50 }

      it "is adjustable to the left" do
        camera.set_deadzone left: DZ_DEFAULT + adjustment
        subject.x -= DZ_MAX[:left] + adjustment + 1
        camera.track subject.rect

        expect(camera.position).to eq(camera_origin.tap { |c| c.x -= 1 })
      end

      it "is adjustable to the right" do
        camera.set_deadzone right: DZ_DEFAULT + adjustment
        subject.x += DZ_MAX[:right] + adjustment + 1
        camera.track subject.rect

        expect(camera.position).to eq(camera_origin.tap { |c| c.x += 1 })
      end

      it "is adjustable upwards" do
        camera.set_deadzone up: adjustment
        subject.y += adjustment + 1
        camera.track subject.rect

        expect(camera.position).to eq(camera_origin.tap { |c| c.y += 1 })
      end

      it "is adjustable downwards" do
        camera.set_deadzone down: DZ_DEFAULT + adjustment
        subject.y -= DZ_MAX[:down] + adjustment + 1
        camera.track subject.rect

        expect(camera.position).to eq(camera_origin.tap { |c| c.y -= 1 })
      end
    end
  end

  describe "origin point" do
    let(:map) { Tiled::Map.new("spec/maps/camera_origin.tmx").tap(&:load) }

    it "offsets the X-axis" do
      expect(camera.x).to eq 5
    end

    it "offsets the Y-axis" do
      expect(camera.y).to eq 10
    end
  end

  describe "#render_rect" do
    context "when the camera position has been adjusted" do
      before { camera.pan x: 50, y: 50 }

      it "adjusts the coordinates by the camera position" do
        expect(camera.render_rect).to include(
          x: -camera.x, y: -camera.y,
          w: map.pixelwidth, h: map.pixelheight
        )
      end

      context "when the camera has been zoomed in" do
        before { camera.zoom_in 0.1 }

        it "makes the map larger" do
          expect(camera.render_rect).to include(w: a_value_between(1682, 1683),
                                                h: a_value_between(1682, 1683))
        end

        it "shifts the camera inward" do
          expect(camera.render_rect).to include(x: a_value_between(-86, -85),
                                                y: a_value_between(-72, -71))
        end
      end

      context "when the camera has been zoomed out" do
        before { camera.zoom_out 0.1 }

        it "makes the map smaller" do
          expect(camera.render_rect).to include(w: a_value_between(1521, 1522),
                                                h: a_value_between(1521, 1522))
        end

        it "shifts the camera outward" do
          expect(camera.render_rect).to include(x: a_value_between(-17, -16),
                                                y: a_value_between(-30, -29))
        end
      end
    end

    context "when the camera is at 0, 0 and zooms out" do
      it "doesn't shift the camera outward" do
        camera.zoom_in 1
        camera.position = [0, 0]
        camera.zoom_out 0.5

        expect(camera.render_rect).to include(x: -camera.x, y: -camera.y)
      end
    end
  end
end
