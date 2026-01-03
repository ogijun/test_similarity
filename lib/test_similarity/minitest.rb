# frozen_string_literal: true

module TestSimilarity
  module MinitestHook
    def run
      trace = Set.new

      tp = TracePoint.new(:call) do |tp|
        next unless TestSimilarity.target_path?(tp.path)

        trace << "#{tp.defined_class}##{tp.method_id}"
      end

      tp.enable
      result = super
      tp.disable

      location = method(name)&.source_location
      TestSimilarity.write(self, trace, location: location)

      result
    end
  end
end
