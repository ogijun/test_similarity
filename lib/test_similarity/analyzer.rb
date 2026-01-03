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

    def find_similar(test_id, threshold: 0.5)
      return [] unless data.key?(test_id)

      target = data[test_id][:signature]

      results = data.filter_map do |id, info|
        next if id == test_id

        score = jaccard(target, info[:signature])
        next if score < threshold

        { test: id, score: score }
      end

      results.sort_by { |r| -r[:score] }
    end

    def diff(test_a, test_b)
      return nil unless data.key?(test_a) && data.key?(test_b)

      sig_a = data[test_a][:signature]
      sig_b = data[test_b][:signature]

      {
        only_in_a: (sig_a - sig_b).to_a.sort,
        only_in_b: (sig_b - sig_a).to_a.sort,
        common: (sig_a & sig_b).to_a.sort,
        score: jaccard(sig_a, sig_b)
      }
    end

    def list(threshold: 0.8)
      if data.empty?
        puts "No recorded tests found in #{@dir}"
        return
      end

      summaries = data.keys.map do |test_id|
        best = find_best_match(test_id)
        { test: test_id, best_match: best }
      end

      # Sort by max similarity (descending), suspicious ones first
      summaries.sort_by! { |s| -(s[:best_match]&.[](:score) || 0) }

      suspicious = summaries.select { |s| (s[:best_match]&.[](:score) || 0) >= threshold }

      puts "Recorded tests: #{data.size}"
      puts "=" * 70
      puts

      if suspicious.any?
        puts "Potentially redundant (>= #{(threshold * 100).to_i}% similar):"
        puts "-" * 70
        suspicious.each do |s|
          score = (s[:best_match][:score] * 100).round(1)
          puts "  #{score}%  #{s[:test]}"
          puts "        -> #{s[:best_match][:test]}"
        end
        puts
      end

      others = summaries - suspicious
      if others.any?
        puts "Other tests:"
        puts "-" * 70
        others.each do |s|
          if s[:best_match]
            score = (s[:best_match][:score] * 100).round(1)
            puts "  #{score}%  #{s[:test]}"
          else
            puts "    -   #{s[:test]}"
          end
        end
        puts
      end

      puts "=" * 70
      puts "Use: rake test_similarity:check[TestClass#test_name] for details"
    end

    def check(test_id, threshold: 0.5)
      unless data.key?(test_id)
        puts "Test not found: #{test_id}"
        puts "Available tests:"
        data.keys.sort.each { |t| puts "  #{t}" }
        return
      end

      similar = find_similar(test_id, threshold: threshold)

      if similar.empty?
        puts "No similar tests found for #{test_id} (threshold: #{(threshold * 100).to_i}%)"
        return
      end

      puts "Similar tests for: #{test_id}"
      puts "=" * 60
      puts

      similar.each do |match|
        d = diff(test_id, match[:test])
        puts "#{(match[:score] * 100).round(1)}% similar: #{match[:test]}"
        puts "-" * 60

        if d[:only_in_a].any?
          puts "  Only in #{test_id.split('#').last}:"
          d[:only_in_a].each { |m| puts "    - #{m}" }
        end

        if d[:only_in_b].any?
          puts "  Only in #{match[:test].split('#').last}:"
          d[:only_in_b].each { |m| puts "    - #{m}" }
        end

        puts "  Common: #{d[:common].size} method(s)"
        puts
      end
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

    def find_best_match(test_id)
      return nil unless data.key?(test_id)

      target = data[test_id][:signature]
      best = nil

      data.each do |id, info|
        next if id == test_id

        score = jaccard(target, info[:signature])
        if best.nil? || score > best[:score]
          best = { test: id, score: score }
        end
      end

      best
    end
  end
end
