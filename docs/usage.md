# Usage

## Running Tests with Recording

After enabling test_similarity in your test helper, run tests with the environment variable:

```
TEST_SIMILARITY=1 bundle exec rails test
```

Or for plain Ruby projects:

```
TEST_SIMILARITY=1 bundle exec rake test
```

Artifacts will be written to `tmp/test_similarity/` by default.

## Rake Tasks

### Report: Overview and Clusters

```
bundle exec rake test_similarity:report
```

Shows a summary and clusters of similar tests:

```
Test Similarity Summary
-----------------------
Total tests: 42

Best-match similarity:
  avg:    0.45
  median: 0.38
  max:    0.95

Similarity clusters (>=80%):
  clusters: 3
  largest:  5 tests

Similarity concentration:
  top 20% of tests account for 67% of high-similarity pairs

Clusters
--------

Cluster 1 (5 tests):
  UserTest#test_invalid_email
    test/models/user_test.rb:15
  UserTest#test_blank_email
    test/models/user_test.rb:22
  ...

  Common code paths (8):
    User#validate
    EmailValidator#call
    ...
```

Custom threshold (default: 80%):

```
bundle exec rake test_similarity:report[70]
```

### Check: Inspect a Specific Test

```
bundle exec rake test_similarity:check[UserTest#test_invalid_email]
```

Shows similar tests with a diff:

```
Similar tests for: UserTest#test_invalid_email
  test/models/user_test.rb:15
============================================================

92.3% similar: UserTest#test_blank_email
  test/models/user_test.rb:22
------------------------------------------------------------
  Only in test_invalid_email:
    - EmailValidator#format_check
  Only in test_blank_email:
    - EmailValidator#presence_check
  Common: 12 method(s)
```

Custom threshold (default: 50%):

```
bundle exec rake test_similarity:check[UserTest#test_invalid_email,70]
```

### List: All Tests Overview

When called without arguments, `check` lists all tests:

```
bundle exec rake test_similarity:check
```

### Clear: Remove Recorded Data

```
bundle exec rake test_similarity:clear
```

## JSON Output

For programmatic access, set `FORMAT=json`:

```
FORMAT=json bundle exec rake test_similarity:check[UserTest#test_invalid_email]
```

```json
{
  "test": {
    "id": "UserTest#test_invalid_email",
    "file": "test/models/user_test.rb",
    "line": 15
  },
  "similar_tests": [
    {
      "test": {
        "id": "UserTest#test_blank_email",
        "file": "test/models/user_test.rb",
        "line": 22
      },
      "similarity": 92.3,
      "only_in_target": ["EmailValidator#format_check"],
      "only_in_similar": ["EmailValidator#presence_check"],
      "common_count": 12
    }
  ]
}
```
