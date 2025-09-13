# frozen_string_literal: true

require "listen"
require "testerobly/configuration"

module Testerobly
  class << self
    attr_accessor :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.load_external_config
    config_file = File.expand_path("config/testerobly.rb", Dir.pwd)
    load config_file if File.exist?(config_file)
  end

  class Main
    PAUSE_SECONDS = 5

    def configuration
      Testerobly::configuration
    end

    def initialize
      log "testerobly starting"

      @queue = Thread::Queue.new
      @pause_until = Time.now

      file_listener = Listen.to(Dir.getwd, relative: true, ignore!: %r{git/HEAD}) do |modified, added|
        process_changes modified, added
      end

      file_listener.start
      capture_input_thread = capture_input

      loop do
        sleep 0.5
        if item = @queue.shift
          capture_input_thread.kill
          log item[:message]
          system item[:command]
          capture_input_thread = capture_input
        end
      rescue Interrupt
        capture_input_thread.kill
        file_listener.stop
        break
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
        when /^lib\/.*\.rb$/
          result = path.gsub %r{^lib/(.+)\.rb$}, 'test/\1_test.rb'
          tests << result if File.exist?(result)
        when /^app\/(channels|controllers|helpers|jobs|models)\/.*\.rb$/
          result = path.gsub %r{^app/(.+)\.rb$}, 'test/\1_test.rb'
          tests << result if File.exist?(result)
        when /^test\/.*_test\.rb$/
          tests << path
        end
      end

      tests.uniq!

      if tests.any?
        command = sprintf configuration.test_command, tests.join(" ")
        message = "#{changes.join ", "} => #{tests.join ", "}"
        @queue << Hash[command:, message:]
      end
    end

    def log(text)
      puts "\e[2m#{text}\e[0m"
    end

    def capture_input
      log "[Enter] #{configuration.test_all_command}"

      Thread.new do
        loop do
          if [ "\r", "\n" ].include?($stdin.getc)
            @queue << { command: configuration.test_all_command, message: configuration.test_all_command }
          end
        end
      end
    end
  end
end

