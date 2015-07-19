require 'spec_helper'

describe ApplePie do
  def app
    ApplePie.new
  end

  describe 'GET /' do
    it "says '200'" do
      get '/'
      expect(last_response.body).to eq('200')
    end
  end
end
