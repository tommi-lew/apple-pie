require 'spec_helper'

describe 'apple pie' do
  def app
    Sinatra::Application
  end

  describe 'GET /' do
    it "says '200'" do
      get '/'
      expect(last_response.body).to eq('200')
    end
  end
end
