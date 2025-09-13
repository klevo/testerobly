# testerobly

* Listen for file changes and run matching tests. 
* Works with [MiniTest](https://github.com/minitest/minitest) out of the box. 
* Can be configured with custom commands to run individual and all tests.
* Can be configured with custom matchers, matching changed files to specific tests.
* Pause and skip during git operations like checkout.
* Run all tests with Enter.
* Fast, simple, stable and resource efficient.

## Installation

Add it to your Gemfile's development group:

```ruby
group :development do
  gem "testerobly"
end
```

Then bundle:

```sh
bundle install

# Recommended: adds bin/testerobly so you don't have to invoke it with "bundle exec testerobly"
bundle binstub testerobly
```

### Rails specific configuration

Create `config/testerobly.rb`:

```ruby
Testerobly.configure do |config|
  config.test_command = "bin/rails test %s" # "%s" will be replaced with the test file paths 
  config.test_all_command = "bin/rails test:all"

  # Optional on-change hook, allowing you to run custom tests when specific file or pattern changes
  # Called for every relative path that changed within your project directory
  config.on_change = Proc.new do |path, tests|
    case path
    when /^app\/models\/stepped\/.*\.rb$/, /^app\/jobs\/stepped\/.*\.rb$/
      tests << "test/models/stepped" << "test/jobs/stepped"
    end
  end
end
```

You can use the above configuration for other types of projects, not just Rails.

## Usage

From your projects root directory run:

```sh
bundle exec testerobly
# OR if you installed the binstub
bin/testerobly
```

Appropriate tests will be run once you edit files. Press Enter to run the all tests command you configured.

Happy testing!

## Development

PRs are welcome. To set up locally from within the checked out repo:

```sh
# Install dependencies
bundle

# Run commands with dev code
ruby -Ilib/ bin/testerobly
```
