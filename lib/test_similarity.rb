# frozen_string_literal: true

require "json"
require "fileutils"
require "pathname"
require "set"

require "test_similarity/version"
require "test_similarity/minitest"
require "test_similarity/railtie" if defined?(Rails::Railtie)

module TestSimilarity
  class << self
    # Where to store per-test artifacts
    attr_accessor :output_dir

    # Which files should be considered "application code"
    attr_accessor :path_filter
  end

  self.output_dir  = "tmp/test_similarity"
  self.path_filter = %r{/app/}

  def self.target_path?(path)
    path_filter === path
  end

  def self.write(test, trace, location: nil)
    FileUtils.mkdir_p(output_dir)

    test_info = {
      class: test.class.name,
      name:  test.name
    }

    if location
      test_info[:file] = relative_path(location[0])
      test_info[:line] = location[1]
    end

    payload = {
      test: test_info,
      signature: trace.to_a.sort,
      signature_size: trace.size
    }

    File.write(
      File.join(output_dir, filename_for(test)),
      JSON.pretty_generate(payload)
    )
  end

  def self.filename_for(test)
    "#{test.class}-#{test.name}.json"
  end

  def self.relative_path(absolute_path)
    Pathname.new(absolute_path).relative_path_from(Pathname.pwd).to_s
  rescue ArgumentError
    absolute_path
  end
end
