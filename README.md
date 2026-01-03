# test_similarity

> Observe how similar your tests are — without judging them.

`test_similarity` records execution signatures of individual tests and helps you see which tests look similar.

This gem does not decide whether your tests are redundant.
It does not fail your test suite.
It simply gives you signals so you can notice when tests start to look too alike.

## What this gem is for

- Getting a sense of how dense or repetitive your test suite has become
- Noticing when regression tests might be overwritten instead of refined
- Periodically observing the current state of your tests
- Supporting human judgement, not replacing it

## What this gem is not for
- Enforcing test quality
- Automatically deleting tests
- Optimizing your test suite
- Failing CI

If you want a tool that tells you what to remove, this gem is not it.

## Supported environments
- Ruby
- Minitest
- Plain Ruby or Rails projects

RSpec and other frameworks are intentionally out of scope (for now).

## How it works

For each test, test_similarity records an execution signature:

- which application-level methods were called
- during that specific test run

Each test produces a small JSON file representing that signature.

The gem itself does not compare tests.
It only records data.

## Usage

1. Install

```ruby
# Gemfile
gem "test_similarity", group: :test
```

```
bundle install
```

2. Enable (explicit opt-in)

```ruby
# test/test_helper.rb
require "test_similarity"
Minitest::Test.prepend(TestSimilarity::MinitestHook)
```

Or conditionally:

```ruby
if ENV["TEST_SIMILARITY"]
  require "test_similarity"
  Minitest::Test.prepend(TestSimilarity::MinitestHook)
end
```

3. Run tests

```
TEST_SIMILARITY=1 bundle exec rails test
```

Artifacts will be written to:

```
tmp/test_similarity/
```

Example:

```
UserTest-test_invalid_email.json
UserTest-test_blank_email.json
```

4. Analyze similarity

After running tests, use the rake task to generate a similarity report:

```
bundle exec rake test_similarity:report
```

This calculates Jaccard similarity between all test pairs and shows those above the threshold (default: 80%).

To specify a custom threshold (e.g., 70%):

```
bundle exec rake test_similarity:report[70]
```

To clear recorded data:

```
bundle exec rake test_similarity:clear
```

## Configuration

```ruby
# test/test_helper.rb

# Filter which paths are recorded (default: /app/)
TestSimilarity.path_filter = %r{/app/}

# Change output directory (default: tmp/test_similarity)
TestSimilarity.output_dir = "tmp/test_similarity"
```
