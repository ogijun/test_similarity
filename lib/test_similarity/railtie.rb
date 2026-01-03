# frozen_string_literal: true

module TestSimilarity
  class Railtie < Rails::Railtie
    rake_tasks do
      load "test_similarity/tasks.rake"
    end
  end
end
