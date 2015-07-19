ENV['RACK_ENV'] = 'test'

require_relative File.join('..', 'app.rb')

require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

require 'rack/test'
require 'rspec'
require 'timecop'

RSpec.configure do |config|
  config.include Rack::Test::Methods

  [:each].each do |x|
    config.before(x) do
    end
  end
end
