# frozen_string_literal: true

require "listen"

PAUSE_SECONDS = 5
QUEUE = Thread::Queue.new
TEST_COMMAND = %(bin/rails test)

module Testerobly
  class Main
    def initialize
      log "testerobly starting"

      @pause_until = Time.now

      file_listener = Listen.to(Dir.getwd, relative: true, ignore!: %r{git/HEAD}) do |modified, added|
        process_changes modified, added
      end

      file_listener.start
      capture_input_thread = capture_input

      loop do
        sleep 0.5
        if item = QUEUE.shift
          capture_input_thread.kill
          log item[:message]
          system item[:command]
          capture_input_thread = capture_input
        end
      end
    end

    def process_changes(modified, added)
      changes = modified + added
      return if changes.empty?

      if changes.include?(".git/HEAD") || changes.include?(".git/logs/HEAD") || changes.include?(".git/index")
        log "git checkout detected, pausing for #{PAUSE_SECONDS}s"
        @pause_until = Time.now + PAUSE_SECONDS
      end

      return if @pause_until > Time.now

      tests = []

      changes.each do |path|
        case path
        when /^app\/(channels|controllers|helpers|jobs|models)\/.*\.rb$/
          result = path.gsub %r{^app/(.+)\.rb$}, 'test/\1_test.rb'
          tests << result if File.exist?(result)
        when /^test\/.*_test\.rb$/
          tests << path
        end
      end

      if tests.any?
        command = "#{TEST_COMMAND} #{tests.join " "}"
        message = "#{changes.join ", "} => #{tests.join ", "}"
        QUEUE << Hash[command:, message:]
      end
    end

    def log(text)
      puts "\e[2m#{text}\e[0m"
    end

    def capture_input
      log "[Enter] rails test:all"

      Thread.new do
        loop do
          if [ "\r", "\n" ].include?($stdin.getc)
            QUEUE << { command: "#{TEST_COMMAND}:all", message: "rails test:all" }
          end
        end
      end
    end
  end
end

