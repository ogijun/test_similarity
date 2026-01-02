require "json"
require "fileutils"
require "set"

require "test_similarity/version"
require "test_similarity/minitest"

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

  def self.write(test, trace)
    FileUtils.mkdir_p(output_dir)

    payload = {
      test: {
        class: test.class.name,
        name:  test.name
      },
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
end
