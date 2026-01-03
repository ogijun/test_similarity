# frozen_string_literal: true

module TestSimilarity
  class Analyzer
    attr_reader :data

    def initialize(dir = TestSimilarity.output_dir)
      @dir = dir
      @data = load_data
    end

    def similarities(threshold: 0.8)
      results = []

      tests = data.keys
      tests.each_with_index do |a, i|
        tests[(i + 1)..].each do |b|
          score = jaccard(data[a][:signature], data[b][:signature])
          next if score < threshold

          results << {
            test_a: a,
            test_b: b,
            score: score
          }
        end
      end

      results.sort_by { |r| -r[:score] }
    end

    def report(threshold: 0.8)
      pairs = similarities(threshold: threshold)

      if pairs.empty?
        puts "No test pairs found with similarity >= #{(threshold * 100).to_i}%"
        return
      end

      puts "Test Similarity Report (threshold: #{(threshold * 100).to_i}%)"
      puts "=" * 60
      puts

      pairs.each do |pair|
        puts "#{(pair[:score] * 100).round(1)}% similar:"
        puts "  - #{pair[:test_a]}"
        puts "  - #{pair[:test_b]}"
        puts
      end

      puts "=" * 60
      puts "Found #{pairs.size} pair(s) above threshold"
    end

    private

    def load_data
      result = {}

      Dir.glob(File.join(@dir, "*.json")).each do |file|
        json = JSON.parse(File.read(file), symbolize_names: true)
        test_id = "#{json[:test][:class]}##{json[:test][:name]}"
        result[test_id] = {
          signature: Set.new(json[:signature]),
          file: file
        }
      end

      result
    end

    def jaccard(set_a, set_b)
      return 0.0 if set_a.empty? && set_b.empty?

      intersection = (set_a & set_b).size.to_f
      union = (set_a | set_b).size.to_f

      intersection / union
    end
  end
end
