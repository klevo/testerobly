Testerobly.configure do |config|
  config.test_command = "bin/test %s"
  config.test_all_command = "bin/test"
  config.on_change = Proc.new do |path, tests|
    if path == "config/testerobly.rb"
      tests << "test/custom_on_change.rb"
    end
  end

  config.bind "s", "say Hello" 
  config.bind "joke", "echo 'This is a funny joke :-)'" 
end
