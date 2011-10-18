require 'simplecov'
require 'mock_redis'

SimpleCov.add_filter 'spec'
SimpleCov.add_filter 'config'
SimpleCov.add_filter 'legacy'
SimpleCov.start

$:.unshift(File.dirname(File.dirname(__FILE__)))

ENV["RACK_ENV"] = "test"
require 'config/environment'

require 'api/v1'
require 'rack/test'
require 'config/logging'

require 'vcr'
VCR.config do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.stub_with :webmock 
end

set :environment, :test


# Run all examples in a transaction
RSpec.configure do |c|
  c.mock_with :rspec
  c.around(:each) do |example|
    SessionManager.connect(MockRedis.new)
    ActiveRecord::Base.connection.transaction do
      example.run 
      raise ActiveRecord::Rollback
    end
  end
end
