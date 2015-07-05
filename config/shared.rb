ENV['BUNDLE_GEMFILE'] = File.expand_path('../Gemfile', File.dirname(__FILE__))

RACK_ENV ||= ENV['RACK_ENV'] || 'development'

require 'bundler/setup'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'github_api'

configure :production, :development, :test do
  enable :logging
end

# Github
Github.configure do |c|
  c.user        = ENV['GITHUB_USER']
  c.repo        = ENV['GITHUB_REPO']
  c.oauth_token = ENV['GITHUB_TOKEN']
end
