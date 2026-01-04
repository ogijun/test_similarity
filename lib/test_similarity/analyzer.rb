# frozen_string_literal: true

module TestSimilarity
  class Analyzer
    attr_reader :data

    def initialize(dir = TestSimilarity.output_dir)
      @dir = dir
      @data = load_data
      @similarities_cache = {}
      @best_matches_cache = nil
    end

    def summary(threshold: 0.8)
      return nil if data.empty?

      pairs = similarities(threshold: threshold)

      # Calculate max similarity for each test
      max_similarities = data.keys.map do |test_id|
        best = find_best_match(test_id)
        best ? best[:score] : 0.0
      end.sort

      avg = max_similarities.sum / max_similarities.size
      median = if max_similarities.size.odd?
        max_similarities[max_similarities.size / 2]
      else
        mid = max_similarities.size / 2
        (max_similarities[mid - 1] + max_similarities[mid]) / 2.0
      end
      max = max_similarities.last

      # Find clusters
      clusters = find_clusters(threshold: threshold)
      largest_cluster = clusters.map(&:size).max || 0

      # Concentration: what % of high-similarity pairs do top 20% of tests account for?
      concentration = calculate_concentration(pairs, top_percent: 0.2)

      {
        total_tests: data.size,
        best_match_avg: avg,
        best_match_median: median,
        best_match_max: max,
        cluster_count: clusters.size,
        largest_cluster: largest_cluster,
        concentration: concentration,
        threshold: threshold
      }
    end

    def print_summary(threshold: 0.8)
      s = summary(threshold: threshold)
      return if s.nil?

      threshold_pct = (threshold * 100).to_i

      puts "Test Similarity Summary"
      puts "-" * 23
      puts "Total tests: #{s[:total_tests]}"
      puts
      puts "Best-match similarity:"
      puts "  avg:    #{s[:best_match_avg].round(2)}"
      puts "  median: #{s[:best_match_median].round(2)}"
      puts "  max:    #{s[:best_match_max].round(2)}"
      puts
      puts "Similarity clusters (>=#{threshold_pct}%):"
      puts "  clusters: #{s[:cluster_count]}"
      puts "  largest:  #{s[:largest_cluster]} tests" if s[:largest_cluster] > 0
      puts
      if s[:concentration]
        puts "Similarity concentration:"
        puts "  top 20% of tests account for #{s[:concentration]}% of high-similarity pairs"
        puts
      end
    end

    def similarities(threshold: 0.8)
      @similarities_cache[threshold] ||= compute_similarities(threshold)
    end

    def report(threshold: 0.8)
      print_summary(threshold: threshold)

      clusters = find_clusters(threshold: threshold)

      if clusters.empty?
        puts "No similarity clusters found."
        return
      end

      puts "Clusters"
      puts "-" * 8

      clusters.sort_by { |c| -c.size }.each_with_index do |cluster, i|
        puts
        puts "Cluster #{i + 1} (#{cluster.size} tests):"
        cluster.each do |test_id|
          loc = format_location(test_id)
          puts "  #{test_id}"
          puts "    #{loc}" if loc
        end

        # Show common code paths
        common = cluster_common_methods(cluster)
        if common.any?
          puts
          puts "  Common code paths (#{common.size}):"
          common.first(10).each { |m| puts "    #{m}" }
          puts "    ... and #{common.size - 10} more" if common.size > 10
        end
      end
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

    def list(threshold: 0.8, format: :text)
      if data.empty?
        if format == :json
          return puts(JSON.pretty_generate({ tests: [], potentially_redundant: [] }))
        end
        return puts("No recorded tests found in #{@dir}")
      end

      print_summary(threshold: threshold) if format == :text

      summaries = data.keys.map { |test_id| { test: test_id, best_match: find_best_match(test_id) } }
      summaries.sort_by! { |s| -(s[:best_match]&.[](:score) || 0) }
      suspicious = summaries.select { |s| (s[:best_match]&.[](:score) || 0) >= threshold }
      threshold_pct = (threshold * 100).to_i

      return puts(JSON.pretty_generate(list_as_json(summaries, suspicious, threshold))) if format == :json

      puts "Recorded tests: #{data.size}"
      puts "=" * 70
      puts

      if suspicious.any?
        puts "Potentially redundant (>= #{threshold_pct}% similar):"
        puts "-" * 70
        suspicious.each do |s|
          score = (s[:best_match][:score] * 100).round(1)
          puts "  #{score}%  #{s[:test]}"
          loc = format_location(s[:test])
          puts "        #{loc}" if loc
          puts "        -> #{s[:best_match][:test]}"
        end
        puts
      end

      others = summaries - suspicious
      if others.any?
        puts "Other tests:"
        puts "-" * 70
        others.each do |s|
          score = s[:best_match] ? (s[:best_match][:score] * 100).round(1) : nil
          puts score ? "  #{score}%  #{s[:test]}" : "    -   #{s[:test]}"
        end
        puts
      end

      puts "=" * 70
      puts "Use: rake test_similarity:check[TestClass#test_name] for details"
    end

    def check(test_id, threshold: 0.5, format: :text)
      print_summary(threshold: threshold) if format == :text

      unless data.key?(test_id)
        if format == :json
          return puts(JSON.pretty_generate({ error: "Test not found", test_id: test_id }))
        end
        puts "Test not found: #{test_id}"
        puts "Available tests:"
        data.keys.sort.each { |t| puts "  #{t}" }
        return
      end

      similar = find_similar(test_id, threshold: threshold)
      threshold_pct = (threshold * 100).to_i

      return puts(JSON.pretty_generate(check_as_json(test_id, similar))) if format == :json

      if similar.empty?
        return puts("No similar tests found for #{test_id} (threshold: #{threshold_pct}%)")
      end

      puts "Similar tests for: #{test_id}"
      loc = format_location(test_id)
      puts "  #{loc}" if loc
      puts "=" * 60
      puts

      similar.each do |match|
        d = diff(test_id, match[:test])
        puts "#{(match[:score] * 100).round(1)}% similar: #{match[:test]}"
        match_loc = format_location(match[:test])
        puts "  #{match_loc}" if match_loc
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

      Pathname.new(@dir).glob("*.json").each do |file|
        json = JSON.parse(file.read, symbolize_names: true)
        test_id = "#{json[:test][:class]}##{json[:test][:name]}"
        result[test_id] = {
          signature: Set.new(json[:signature]),
          source_file: json[:test][:file],
          source_line: json[:test][:line]
        }
      end

      result
    end

    def compute_similarities(threshold)
      results = []

      tests = data.keys
      tests.each_with_index do |a, i|
        tests[(i + 1)..].each do |b|
          score = jaccard(data[a][:signature], data[b][:signature])
          next if score < threshold

          results << { test_a: a, test_b: b, score: score }
        end
      end

      results.sort_by { |r| -r[:score] }
    end

    def compute_best_matches
      result = {}

      tests = data.keys
      tests.each_with_index do |a, i|
        tests.each_with_index do |b, j|
          next if i == j

          score = jaccard(data[a][:signature], data[b][:signature])
          if result[a].nil? || score > result[a][:score]
            result[a] = { test: b, score: score }
          end
        end
      end

      result
    end

    def format_location(test_id)
      info = data[test_id]
      return nil unless info && info[:source_file]

      "#{info[:source_file]}:#{info[:source_line]}"
    end

    def test_info_as_json(test_id)
      info = data[test_id]
      result = { id: test_id }
      result[:file] = info[:source_file] if info[:source_file]
      result[:line] = info[:source_line] if info[:source_line]
      result
    end

    def check_as_json(test_id, similar)
      result = {
        test: test_info_as_json(test_id),
        similar_tests: []
      }

      similar.each do |match|
        d = diff(test_id, match[:test])
        result[:similar_tests] << {
          test: test_info_as_json(match[:test]),
          similarity: (match[:score] * 100).round(1),
          only_in_target: d[:only_in_a],
          only_in_similar: d[:only_in_b],
          common_count: d[:common].size
        }
      end

      result
    end

    def list_as_json(summaries, suspicious, threshold)
      {
        total_tests: data.size,
        threshold: (threshold * 100).to_i,
        potentially_redundant: suspicious.map do |s|
          {
            test: test_info_as_json(s[:test]),
            most_similar: test_info_as_json(s[:best_match][:test]),
            similarity: (s[:best_match][:score] * 100).round(1)
          }
        end,
        all_tests: summaries.map do |s|
          entry = test_info_as_json(s[:test])
          if s[:best_match]
            entry[:max_similarity] = (s[:best_match][:score] * 100).round(1)
            entry[:most_similar_to] = s[:best_match][:test]
          end
          entry
        end
      }
    end

    def jaccard(set_a, set_b)
      return 0.0 if set_a.empty? && set_b.empty?

      intersection = (set_a & set_b).size.to_f
      union = (set_a | set_b).size.to_f

      intersection / union
    end

    def find_best_match(test_id)
      return nil unless data.key?(test_id)

      @best_matches_cache ||= compute_best_matches
      @best_matches_cache[test_id]
    end

    def cluster_common_methods(cluster)
      return [] if cluster.empty?

      signatures = cluster.map { |test_id| data[test_id][:signature] }
      common = signatures.reduce(:&)
      common.to_a.sort
    end

    def calculate_concentration(pairs, top_percent: 0.2)
      return nil if pairs.empty?

      # Count how many pairs each test appears in
      test_pair_count = Hash.new(0)
      pairs.each do |p|
        test_pair_count[p[:test_a]] += 1
        test_pair_count[p[:test_b]] += 1
      end

      # Sort tests by pair count (descending)
      sorted_tests = test_pair_count.sort_by { |_, count| -count }

      # Top 20% of tests
      top_count = [(sorted_tests.size * top_percent).ceil, 1].max
      top_tests = sorted_tests.first(top_count).map(&:first).to_set

      # Count pairs involving top tests
      pairs_with_top = pairs.count { |p| top_tests.include?(p[:test_a]) || top_tests.include?(p[:test_b]) }

      ((pairs_with_top.to_f / pairs.size) * 100).round(0)
    end

    def find_clusters(threshold: 0.8)
      pairs = similarities(threshold: threshold)
      return [] if pairs.empty?

      # Union-Find
      parent = {}
      data.keys.each { |t| parent[t] = t }

      find = ->(x) {
        parent[x] = find.call(parent[x]) if parent[x] != x
        parent[x]
      }

      union = ->(x, y) {
        px, py = find.call(x), find.call(y)
        parent[px] = py if px != py
      }

      pairs.each { |p| union.call(p[:test_a], p[:test_b]) }

      # Group by root
      groups = Hash.new { |h, k| h[k] = [] }
      data.keys.each { |t| groups[find.call(t)] << t }

      # Return only clusters with more than 1 member
      groups.values.select { |g| g.size > 1 }
    end
  end
end
