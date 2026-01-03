# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "test_similarity"
require "test_similarity/analyzer"
require "minitest/autorun"
require "fileutils"
require "json"

module TestSimilarity
  class TestCase < Minitest::Test
    def setup
      @original_output_dir = TestSimilarity.output_dir
      @test_output_dir = File.join(Dir.tmpdir, "test_similarity_test_#{$$}")
      TestSimilarity.output_dir = @test_output_dir
      FileUtils.mkdir_p(@test_output_dir)
    end

    def teardown
      FileUtils.rm_rf(@test_output_dir) if @test_output_dir && Dir.exist?(@test_output_dir)
      TestSimilarity.output_dir = @original_output_dir
    end

    def write_test_data(test_class, test_name, signature, file: nil, line: nil)
      test_info = { class: test_class, name: test_name }
      test_info[:file] = file if file
      test_info[:line] = line if line

      payload = {
        test: test_info,
        signature: signature.to_a.sort,
        signature_size: signature.size
      }

      filename = "#{test_class}-#{test_name}.json"
      File.write(File.join(@test_output_dir, filename), JSON.pretty_generate(payload))
    end
  end
end
