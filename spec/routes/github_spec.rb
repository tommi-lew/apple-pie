require 'spec_helper'

describe ApplePie do
  def app
    ApplePie.new
  end

  let(:logger) { instance_spy('Logger') }

  before do
    allow(Logger).to receive(:new).with(any_args).and_return(logger)
  end

  describe 'POST /gh_webhook' do
    describe 'action is not opened' do
      it 'logs and stop request' do
        post '/gh_webhook', { action: 'merged' }.to_json

        expect(logger).to have_received(:info).with('Do not handle this action.')
        expect(last_response.status).to eq(200)
      end
    end

    describe 'ui status text' do
      it 'update body with ui status text' do
        ENV['GITHUB_USER'] = 'github_user'
        ENV['GITHUB_REPO'] = 'github_repo'

        @github = double('Github')
        @pull_requests_ns = double('Pull Request Namespace')
        pull_request_update_response = double('pull_request_update_response', status: 200)
        expect(Github).to receive(:new).and_return(@github)
        expect(@github).to receive(:pull_requests).and_return(@pull_requests_ns)
        expect(@pull_requests_ns).
            to receive(:update).
            with('github_user', 'github_repo', 1, body: update_status('', { ui: :pending }))
            .and_return(pull_request_update_response)

        post '/gh_webhook', { action: 'opened', number: 1, pull_request: { body: '' } }.to_json
      end
    end
  end
end
