# Configuration

All configuration is done in your test helper file (e.g., `test/test_helper.rb`).

## Path Filter

Controls which methods are recorded in the execution signature.

```ruby
# Default: records methods under /app/
TestSimilarity.path_filter = %r{/app/}

# Record only model methods
TestSimilarity.path_filter = %r{/app/models/}

# Record methods from your lib directory
TestSimilarity.path_filter = %r{/lib/}

# Multiple paths (use alternation)
TestSimilarity.path_filter = %r{/app/|/lib/}
```

Methods from gems, Ruby standard library, and test files are excluded by default.

## Output Directory

Where JSON signature files are written.

```ruby
# Default
TestSimilarity.output_dir = "tmp/test_similarity"

# Custom location
TestSimilarity.output_dir = "tmp/my_similarity_data"
```

## Conditional Recording

Enable recording only when needed:

```ruby
if ENV["TEST_SIMILARITY"]
  require "test_similarity"
  Minitest::Test.prepend(TestSimilarity::MinitestHook)
end
```

This keeps test runs fast when you don't need similarity data.

## Rails Integration

For Rails projects, the rake tasks are automatically available via Railtie.

For non-Rails projects, add to your Rakefile:

```ruby
require "test_similarity/tasks"
```
