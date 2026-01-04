# test_similarity

> Observe how similar your tests are — without judging them.

`test_similarity` records execution signatures of individual tests and helps you see which tests look similar.

## Philosophy

This gem does not decide whether your tests are redundant.
It does not fail your test suite.
It simply gives you signals so you can notice when tests start to look too alike.

**What this gem is for:**

- Getting a sense of how dense or repetitive your test suite has become
- Noticing when regression tests might be overwritten instead of refined
- Periodically observing the current state of your tests
- Supporting human judgement, not replacing it

**What this gem is not for:**

- Enforcing test quality
- Automatically deleting tests
- Failing CI

## Quick Start

1. Add to your Gemfile:

```ruby
gem "test_similarity", group: :test
```

2. Enable in test helper:

```ruby
# test/test_helper.rb
if ENV["TEST_SIMILARITY"]
  require "test_similarity"
  Minitest::Test.prepend(TestSimilarity::MinitestHook)
end
```

3. Run tests and analyze:

```
TEST_SIMILARITY=1 bundle exec rake test
bundle exec rake test_similarity:report
```

## Documentation

- [Usage](docs/usage.md) - Rake tasks, output examples, JSON format
- [Configuration](docs/configuration.md) - Path filters, output directory, Rails integration

## Supported Environments

- Ruby + Minitest
- Plain Ruby or Rails projects

RSpec is out of scope.
