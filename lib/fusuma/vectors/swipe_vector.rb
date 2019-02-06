module Fusuma
  module Vectors
    # vector data
    class SwipeVector < BaseVector
      TYPE = 'swipe'.freeze
      EVENT = 'swipe'.freeze

      BASE_THERESHOLD = 10
      BASE_INTERVAL   = 0.5

      def initialize(finger, move_x = 0, move_y = 0)
        @finger = finger.to_i
        @x = move_x.to_f
        @y = move_y.to_f
      end
      attr_reader :finger, :x, :y

      def direction
        return x > 0 ? 'right' : 'left' if x.abs > y.abs

        y > 0 ? 'down' : 'up'
      end

      def enough?
        MultiLogger.debug(x: x, y: y)
        enough_distance? && enough_interval?
      end

      private

      def enough_distance?
        (x.abs > threshold) || (y.abs > threshold)
      end

      def enough_interval?
        return true if first_time?
        return true if (Time.now - self.class.last_time) > interval_time

        false
      end

      def first_time?
        !self.class.last_time
      end

      def threshold
        @threshold ||= BASE_THERESHOLD * Config.threshold(self)
      end

      def interval_time
        @interval_time ||= BASE_INTERVAL * Config.interval(self)
      end

      class << self
        attr_reader :last_time

        def generate(events)
          return if events.first.gesture != EVENT

          generator = Generator.new(events)
          move_x = generator.avg_attrs(:move_x)
          move_y = generator.avg_attrs(:move_y)
          new(generator.finger, move_x, move_y).tap do |v|
            return nil unless v.enough?

            Generator.prev_vector = self
          end
        end

        def touch_last_time
          @last_time = Time.now
        end
      end
    end
  end
end