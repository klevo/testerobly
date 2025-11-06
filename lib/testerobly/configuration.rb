# frozen_string_literal: true

module Testerobly
  class Configuration
    attr_accessor :test_command, :on_change
    attr_reader :keys

    def initialize
      @test_command = "bin/test %s"
      @keys = {}
    end

    def bind(label, command)
      @keys[label] = command
    end

    def test_all_command=(command)
      bind "", command
    end
  end
end
