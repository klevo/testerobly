Testerobly.configure do |config|
  config.test_command = "ruby %s"
  config.test_all_command = "echo 'sample test all command'"
  config.on_change = Proc.new do |path, tests|
    if path == "config/testerobly.rb"
      tests << "test/custom_on_change.rb"
    end
  end

  config.bind "s", "say Hello" 
  config.bind "joke", "echo 'This is a funny joke :-)'" 
end
