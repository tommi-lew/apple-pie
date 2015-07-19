require_relative File.join('config', 'shared.rb')

require 'sinatra/base'

require 'bundler/setup'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'github_api'

require_relative 'routes/init'
require_relative 'helpers/helpers'

class ApplePie < Sinatra::Base
  configure :production, :development, :test do
    enable :logging
  end

  # Github
  Github.configure do |c|
    c.user        = ENV['GITHUB_USER']
    c.repo        = ENV['GITHUB_REPO']
    c.oauth_token = ENV['GITHUB_TOKEN']
  end
end
