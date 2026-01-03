# frozen_string_literal: true

require "test_helper"

# Sample application code to be traced
module SampleApp
  class User
    def validate
      check_email
      check_name
    end

    def check_email
      true
    end

    def check_name
      true
    end
  end
end

class MinitestHookTest < TestSimilarity::TestCase
  def setup
    super
    @original_path_filter = TestSimilarity.path_filter
    # Match this test file so SampleApp methods are traced
    TestSimilarity.path_filter = %r{minitest_hook_test\.rb}
  end

  def teardown
    TestSimilarity.path_filter = @original_path_filter
    super
  end

  def test_hook_records_method_calls
    # Create a test class that uses the hook with an actual test method
    test_class = Class.new(Minitest::Test) do
      prepend TestSimilarity::MinitestHook

      define_method(:test_sample) do
        user = SampleApp::User.new
        user.validate
      end
    end

    # Give the class a name
    Object.const_set(:SampleTest, test_class)

    # Run the test
    test_instance = test_class.new("test_sample")
    test_instance.run

    # Check that a file was written
    files = Dir.glob(File.join(TestSimilarity.output_dir, "*.json"))
    assert_equal 1, files.size

    # Check the content
    data = JSON.parse(File.read(files.first), symbolize_names: true)
    assert_equal "SampleTest", data[:test][:class]
    assert_equal "test_sample", data[:test][:name]

    # Check that source location is recorded
    assert data[:test][:file], "Expected file path to be recorded"
    assert data[:test][:line], "Expected line number to be recorded"

    signature = data[:signature]
    assert_includes signature, "SampleApp::User#validate"
    assert_includes signature, "SampleApp::User#check_email"
    assert_includes signature, "SampleApp::User#check_name"
  ensure
    Object.send(:remove_const, :SampleTest) if defined?(SampleTest)
  end

  def test_hook_respects_path_filter
    TestSimilarity.path_filter = %r{/nonexistent_path/}

    test_class = Class.new(Minitest::Test) do
      prepend TestSimilarity::MinitestHook

      define_method(:test_filtered) do
        user = SampleApp::User.new
        user.validate
      end
    end

    test_instance = test_class.new("test_filtered")
    test_instance.run

    files = Dir.glob(File.join(TestSimilarity.output_dir, "*.json"))
    assert_equal 1, files.size

    data = JSON.parse(File.read(files.first), symbolize_names: true)
    # Signature should be empty because path filter didn't match
    assert_equal [], data[:signature]
  end
end
