# frozen_string_literal: true

module Testerobly
  class Configuration
    attr_accessor :test_command, :test_all_command

    def initialize
      @test_command = "bin/test %s"
      @test_all_command = "bin/test"
    end
  end
end
