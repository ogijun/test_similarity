# frozen_string_literal: true

namespace :test_similarity do
  task_deps = defined?(Rails::Railtie) ? [:environment] : []

  desc "Analyze test similarity from recorded data"
  task :report, [:threshold] => task_deps do |_t, args|
    require "test_similarity"
    require "test_similarity/analyzer"

    threshold = (args[:threshold] || 80).to_f / 100
    analyzer = TestSimilarity::Analyzer.new
    analyzer.report(threshold: threshold)
  end

  desc "Check similar tests for a specific test (with diff), or list all tests. Set FORMAT=json for JSON output."
  task :check, [:test_id, :threshold] => task_deps do |_t, args|
    require "test_similarity"
    require "test_similarity/analyzer"

    analyzer = TestSimilarity::Analyzer.new
    format = ENV["FORMAT"] == "json" ? :json : :text

    if args[:test_id]
      threshold = (args[:threshold] || 50).to_f / 100
      analyzer.check(args[:test_id], threshold: threshold, format: format)
    else
      threshold = (args[:threshold] || 80).to_f / 100
      analyzer.list(threshold: threshold, format: format)
    end
  end

  desc "Clear recorded test similarity data"
  task :clear => task_deps do
    require "test_similarity"

    dir = TestSimilarity.output_dir
    if Dir.exist?(dir)
      FileUtils.rm_rf(dir)
      puts "Cleared #{dir}"
    else
      puts "Nothing to clear"
    end
  end
end
