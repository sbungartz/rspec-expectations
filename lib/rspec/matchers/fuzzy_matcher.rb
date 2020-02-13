module RSpec
  module Matchers
    # Provides a means to fuzzy-match between two arbitrary objects.
    # Understands array/hash nesting. Uses `===` or `==` to
    # perform the matching.
    module FuzzyMatcher
      Result = Struct.new(:match?, :failure_messages)

      # @api private
      def self.values_match?(expected, actual)
        if Hash === actual
          return hashes_match?(expected, actual) if Hash === expected
        elsif Array === expected && Enumerable === actual && !(Struct === actual)
          return arrays_match?(expected, actual.to_a)
        end

        return Result.new(true) if expected == actual

        begin
          matches = expected === actual
          failure_message = nil
          if !matches && expected.respond_to?(:failure_message)
            failure_message = expected.failure_message
          end
          Result.new(matches, failure_message)
        rescue ArgumentError
          # Some objects, like 0-arg lambdas on 1.9+, raise
          # ArgumentError for `expected === actual`.
          Result.new(false)
        end
      end

      # @private
      def self.arrays_match?(expected_list, actual_list)
        return Result.new(false) if expected_list.size != actual_list.size

        results = expected_list.zip(actual_list).map do |expected, actual|
          if expected.respond_to?(:with_verb_description)
            expected.with_verb_description do
              values_match?(expected, actual)
            end
          else
            values_match?(expected, actual)
          end
        end

        if results.all?(&:match?)
          Result.new(true)
        else
          index = -1
          messages = results.map do |result|
            index += 1
            "Entry [#{index}]: #{result.failure_messages}" unless result.match?
          end
          composed_message = messages.compact.join("\n")
          Result.new(false, composed_message)
        end
      end

      # @private
      def self.hashes_match?(expected_hash, actual_hash)
        return false if expected_hash.size != actual_hash.size

        expected_hash.all? do |expected_key, expected_value|
          actual_value = actual_hash.fetch(expected_key) { return false }
          values_match?(expected_value, actual_value)
        end
      end

      private_class_method :arrays_match?, :hashes_match?
    end
  end
end
