# frozen_string_literal: true

require_relative "test_helper"

class TesteroblyTest < Minitest::Test
  def setup
    @original_configuration = Testerobly.configuration
    Testerobly.configuration = Testerobly::Configuration.new
  end

  def teardown
    Testerobly.configuration = @original_configuration
  end

  def test_configuration_defaults_and_bind
    config = Testerobly.configuration

    assert_equal "bin/test %s", config.test_command
    assert_equal({}, config.keys)
    assert_nil config.on_change

    config.bind("s", "echo hi")
    config.test_all_command = "bin/test"

    assert_equal "echo hi", config.keys["s"]
    assert_equal "bin/test", config.keys[""]
  end

  def test_configure_yields_configuration
    Testerobly.configure do |config|
      config.test_command = "ruby %s"
    end

    assert_equal "ruby %s", Testerobly.configuration.test_command
  end

  def test_process_changes_enqueues_matching_tests
    with_tmp_project do |dir|
      write_file(dir, "lib/foo.rb", "# frozen_string_literal: true\n")
      write_file(dir, "test/foo_test.rb", "# frozen_string_literal: true\n")

      main = build_main

      Dir.chdir(dir) do
        main.process_changes(["lib/foo.rb"], [])
      end

      queue = main.instance_variable_get(:@queue)

      assert_equal 1, queue.size
      item = queue.pop
      assert_equal "bin/test test/foo_test.rb", item[:command]
      assert_equal "lib/foo.rb => test/foo_test.rb", item[:message]
    end
  end

  def test_process_changes_applies_on_change_hook
    with_tmp_project do |dir|
      write_file(dir, "lib/foo.rb", "# frozen_string_literal: true\n")
      write_file(dir, "test/foo_test.rb", "# frozen_string_literal: true\n")
      write_file(dir, "test/extra_test.rb", "# frozen_string_literal: true\n")

      Testerobly.configuration.on_change = Proc.new do |_path, tests|
        tests << "test/extra_test.rb"
      end

      main = build_main

      Dir.chdir(dir) do
        main.process_changes(["lib/foo.rb"], [])
      end

      queue = main.instance_variable_get(:@queue)

      assert_equal 1, queue.size
      item = queue.pop
      assert_equal "bin/test test/foo_test.rb test/extra_test.rb", item[:command]
    end
  end

  private

  def build_main
    main = Testerobly::Main.allocate
    main.instance_variable_set(:@queue, Thread::Queue.new)
    main.instance_variable_set(:@pause_until, Time.now - 1)
    main
  end

  def with_tmp_project
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "lib"))
      FileUtils.mkdir_p(File.join(dir, "test"))
      yield dir
    end
  end

  def write_file(base, relative_path, contents)
    full_path = File.join(base, relative_path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, contents)
  end
end
