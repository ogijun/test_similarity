# frozen_string_literal: true

require "test_helper"

class AnalyzerTest < TestSimilarity::TestCase
  def test_diff_shows_methods_only_in_first_test
    write_test_data("UserTest", "test_a", Set.new(%w[validate save]))
    write_test_data("UserTest", "test_b", Set.new(%w[save]))

    analyzer = TestSimilarity::Analyzer.new
    result = analyzer.diff("UserTest#test_a", "UserTest#test_b")

    assert_equal %w[validate], result[:only_in_a]
  end

  def test_diff_shows_methods_only_in_second_test
    write_test_data("UserTest", "test_a", Set.new(%w[save]))
    write_test_data("UserTest", "test_b", Set.new(%w[save validate]))

    analyzer = TestSimilarity::Analyzer.new
    result = analyzer.diff("UserTest#test_a", "UserTest#test_b")

    assert_equal %w[validate], result[:only_in_b]
  end

  def test_diff_shows_common_methods
    write_test_data("UserTest", "test_a", Set.new(%w[save validate]))
    write_test_data("UserTest", "test_b", Set.new(%w[save delete]))

    analyzer = TestSimilarity::Analyzer.new
    result = analyzer.diff("UserTest#test_a", "UserTest#test_b")

    assert_equal %w[save], result[:common]
  end

  def test_diff_returns_nil_for_unknown_test
    write_test_data("UserTest", "test_a", Set.new(%w[save]))

    analyzer = TestSimilarity::Analyzer.new

    assert_nil analyzer.diff("UserTest#test_a", "UserTest#unknown")
  end

  def test_find_similar_returns_tests_above_threshold
    write_test_data("UserTest", "test_a", Set.new(%w[m1 m2 m3 m4 m5]))
    write_test_data("UserTest", "test_b", Set.new(%w[m1 m2 m3 m4 m5]))  # identical
    write_test_data("UserTest", "test_c", Set.new(%w[x y z]))           # completely different

    analyzer = TestSimilarity::Analyzer.new
    similar = analyzer.find_similar("UserTest#test_a", threshold: 0.5)

    assert_equal 1, similar.size
    assert_equal "UserTest#test_b", similar.first[:test]
  end

  def test_find_similar_excludes_tests_below_threshold
    write_test_data("UserTest", "test_a", Set.new(%w[m1 m2 m3 m4 m5]))
    write_test_data("UserTest", "test_b", Set.new(%w[m1 x y z w]))  # only 1 common out of 9 unique

    analyzer = TestSimilarity::Analyzer.new
    similar = analyzer.find_similar("UserTest#test_a", threshold: 0.5)

    assert_empty similar
  end

  def test_find_similar_returns_empty_for_unknown_test
    analyzer = TestSimilarity::Analyzer.new

    assert_empty analyzer.find_similar("Unknown#test", threshold: 0.5)
  end

  def test_similarities_finds_similar_pairs
    write_test_data("UserTest", "test_a", Set.new(%w[m1 m2 m3]))
    write_test_data("UserTest", "test_b", Set.new(%w[m1 m2 m3]))  # identical
    write_test_data("UserTest", "test_c", Set.new(%w[x y z]))     # different

    analyzer = TestSimilarity::Analyzer.new
    pairs = analyzer.similarities(threshold: 0.8)

    assert_equal 1, pairs.size
    pair = pairs.first
    assert_includes [pair[:test_a], pair[:test_b]], "UserTest#test_a"
    assert_includes [pair[:test_a], pair[:test_b]], "UserTest#test_b"
  end

  def test_similarities_returns_empty_when_no_similar_tests
    write_test_data("UserTest", "test_a", Set.new(%w[m1 m2]))
    write_test_data("UserTest", "test_b", Set.new(%w[x y]))

    analyzer = TestSimilarity::Analyzer.new
    pairs = analyzer.similarities(threshold: 0.8)

    assert_empty pairs
  end

  def test_similarities_orders_by_most_similar_first
    write_test_data("Test", "a", Set.new(%w[m1 m2 m3]))
    write_test_data("Test", "b", Set.new(%w[m1 m2 m3]))      # 100% similar to a
    write_test_data("Test", "c", Set.new(%w[m1 m2 m3 m4]))   # 75% similar to a

    analyzer = TestSimilarity::Analyzer.new
    pairs = analyzer.similarities(threshold: 0.7)

    assert_equal 1.0, pairs.first[:score]
  end

  def test_similarities_returns_same_object_for_same_threshold
    write_test_data("Test", "a", Set.new(%w[m1 m2 m3]))
    write_test_data("Test", "b", Set.new(%w[m1 m2 m3]))

    analyzer = TestSimilarity::Analyzer.new
    first_call = analyzer.similarities(threshold: 0.8)
    second_call = analyzer.similarities(threshold: 0.8)

    assert_same first_call, second_call
  end

  def test_similarities_returns_different_results_for_different_thresholds
    write_test_data("Test", "a", Set.new(%w[m1 m2 m3 m4]))
    write_test_data("Test", "b", Set.new(%w[m1 m2 m3]))      # 75% similar to a and c
    write_test_data("Test", "c", Set.new(%w[m1 m2 m3 m4]))   # 100% similar to a

    analyzer = TestSimilarity::Analyzer.new
    high_threshold = analyzer.similarities(threshold: 0.9)
    low_threshold = analyzer.similarities(threshold: 0.7)

    assert_equal 1, high_threshold.size   # only a-c (100%)
    assert_equal 3, low_threshold.size    # a-b, a-c, b-c
  end

  def test_find_best_match_returns_consistent_results
    write_test_data("Test", "a", Set.new(%w[m1 m2 m3]))
    write_test_data("Test", "b", Set.new(%w[m1 m2 m3]))  # 100% similar
    write_test_data("Test", "c", Set.new(%w[m1 m2]))     # 66% similar

    analyzer = TestSimilarity::Analyzer.new

    first_call = analyzer.find_similar("Test#a", threshold: 0.0).first
    second_call = analyzer.find_similar("Test#a", threshold: 0.0).first

    assert_equal first_call[:test], second_call[:test]
    assert_equal first_call[:score], second_call[:score]
  end

  def test_find_best_match_finds_correct_match_for_each_test
    write_test_data("Test", "a", Set.new(%w[m1 m2 m3]))
    write_test_data("Test", "b", Set.new(%w[m1 m2 m3]))  # 100% similar to a
    write_test_data("Test", "c", Set.new(%w[x y z]))     # 0% similar to a, b

    analyzer = TestSimilarity::Analyzer.new

    similar_to_a = analyzer.find_similar("Test#a", threshold: 0.5)
    similar_to_c = analyzer.find_similar("Test#c", threshold: 0.5)

    assert_equal 1, similar_to_a.size
    assert_equal "Test#b", similar_to_a.first[:test]
    assert_empty similar_to_c
  end

  def test_separate_analyzer_instances_have_independent_caches
    write_test_data("Test", "a", Set.new(%w[m1 m2]))
    write_test_data("Test", "b", Set.new(%w[m1 m2]))

    analyzer1 = TestSimilarity::Analyzer.new
    analyzer2 = TestSimilarity::Analyzer.new

    result1 = analyzer1.similarities(threshold: 0.8)
    result2 = analyzer2.similarities(threshold: 0.8)

    refute_same result1, result2
  end

  def test_summary_with_single_test
    write_test_data("Test", "only", Set.new(%w[m1 m2]))

    analyzer = TestSimilarity::Analyzer.new
    summary = analyzer.summary(threshold: 0.8)

    assert_equal 1, summary[:total_tests]
    assert_equal 0, summary[:cluster_count]
  end

  def test_summary_with_empty_data
    analyzer = TestSimilarity::Analyzer.new
    summary = analyzer.summary(threshold: 0.8)

    assert_nil summary
  end
end
