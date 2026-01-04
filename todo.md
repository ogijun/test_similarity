# TODO

## Performance

- [ ] Similarity calculation is O(N^2) - consider LSH or MinHash for large suites
- [ ] Optimize Jaccard calculation (use smaller set first algorithm)
- [ ] Optimize compute_best_matches (derive from pairs instead of O(n²) calculation)
- [ ] Parallel test support (thread-safe file writing)
- [ ] Incremental analysis (only re-analyze changed tests)
- [ ] Cache invalidation mechanism (memory management, data change detection)
- [ ] Lazy loading of signature data (only if > 10,000 tests) - low priority

## Features

- [ ] Trend tracking (compare similarity over time/commits) - future enhancement
- [ ] Ignore list (exclude specific tests or patterns from analysis)
- [ ] Signature diff between two test runs
- [ ] Export to CSV

## Output

- [ ] HTML report with interactive visualization
- [ ] Similarity heatmap/matrix view
- [ ] Integration with CI (warning comments on PR, no failure)

## Code Quality

- [ ] Extract output logic from Analyzer (Formatter class or similar)
- [ ] Error handling for JSON parsing and file I/O (skip invalid files, log errors)
- [ ] Handle filename collisions (same test class/method names, parallel execution)
- [ ] Handle edge cases: empty signatures, single-element signatures
- [ ] More edge case tests (empty signatures, unicode in test names)
- [ ] Benchmark tests for large datasets
- [ ] Rubocop configuration

## Documentation

- [ ] Non-Rails usage guide (plain Ruby, other frameworks)
- [ ] Troubleshooting guide
- [ ] Examples with real-world use cases
- [ ] CHANGELOG

## Out of Scope (intentionally)

- RSpec support
- Automatic test deletion suggestions
- CI failure mode
