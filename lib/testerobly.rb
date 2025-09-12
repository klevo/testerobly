# frozen_string_literal: true

require "listen"

QUEUE = Thread::Queue.new
TEST_COMMAND = %(bin/rails test)

module Testeribly
  class Main
    def initialize
      file_listener = Listen.to(Dir.getwd, relative: true) do |modified, added|
        next if git_working?

        changes = modified + added
        # puts "Changes: #{changes}"
        next if changes.empty?

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

      log "testerobly starting"
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

    def git_working?
      File.exist?(".git/index.lock")
    end
  end
end

