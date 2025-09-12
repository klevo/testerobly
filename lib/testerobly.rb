# frozen_string_literal: true

require "listen"

APP_NAME = "testerobly"
DATA_FILE = "projects"
DOTFILE = ".localhost"
PORT_RANGE = (30_000..60_000)

module Testeribly
  class Main
    def initialize
      puts "testerobly here"
    end
  end
end
