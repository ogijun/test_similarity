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

      TestSimilarity.write(self, trace)

      result
    end
  end
end
