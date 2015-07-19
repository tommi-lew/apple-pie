require 'spec_helper'

describe ApplePie do
  def app
    ApplePie.new
  end

  let(:logger) { instance_spy('Logger') }

  before do
    allow(Logger).to receive(:new).with(any_args).and_return(logger)
  end

  describe 'POST /pt_activity_web_hook' do
    context 'pivotal tracker activity' do
      describe 'kind is not comment_create_activity' do
        it 'logs and stop request' do
          post '/pt_activity_web_hook', { kind: 'random_activity' }.to_json

          expect(logger).to have_received(:info).with('Do not handle this activity.')
          expect(last_response.status).to eq(200)
        end
      end

      context 'appropriate text not found' do
        it 'logs and stop request' do
          post '/pt_activity_web_hook', { kind: 'comment_create_activity', changes: [{ new_values: { text: 'quick brown fox' } }] }.to_json

          expect(logger).to have_received(:info).with('No further action, ui approval text not found.')
          expect(last_response.status).to eq(200)
        end
      end
    end

    context 'pull request' do
      before do
        @github = double('Github')
        @pull_requests_ns = double('Pull Request Namespace')
        expect(Github).to receive(:new).and_return(@github)
      end

      it 'looks for a matching pull request based on the pivotal tracker story id' do
        pull_requests = []
        pull_requests << instance_double('pull_request', title: '[#22222222] Story 2')
        pull_requests << instance_double('pull_request', title: '[#11111111] Story 1', body: '', number: 1)
        pull_request_update_response = double('pull_request_update_response', status: 200)

        expect(@github).to receive(:pull_requests).and_return(@pull_requests_ns).twice
        expect(@pull_requests_ns).to receive(:list).and_return(pull_requests)
        expect(@pull_requests_ns).to receive(:update).with(any_args).and_return(pull_request_update_response)

        post '/pt_activity_web_hook', { kind: 'comment_create_activity', primary_resources: [{ id: 11111111 }], changes: [{ new_values: { text: 'ui ok' } }] }.to_json
      end

      describe 'pull request not found' do
        it 'logs and stop request' do
          pull_requests = []

          expect(@github).to receive(:pull_requests).and_return(@pull_requests_ns)
          expect(@pull_requests_ns).to receive(:list).and_return(pull_requests)

          post '/pt_activity_web_hook', { kind: 'comment_create_activity', primary_resources: [{ id: 11111111 }], changes: [{ new_values: { text: 'ui ok' } }] }.to_json

          expect(logger).to have_received(:info).with('No further action, no matching pull requests.')
          expect(last_response.status).to eq(200)
        end
      end

      it 'updates pull request' do
        ENV['GITHUB_USER'] = 'github_user'
        ENV['GITHUB_REPO'] = 'github_repo'

        pull_request = instance_double('pull_request', title: '11111111', number: 1, body: '')
        pull_requests = [pull_request]
        pull_request_update_response = double('pull_request_update_response', status: 200)

        expect(@github).to receive(:pull_requests).and_return(@pull_requests_ns).twice
        expect(@pull_requests_ns).to receive(:list).and_return(pull_requests)
        expect(@pull_requests_ns).to receive(:update).
                                         with('github_user', 'github_repo', 1, body: update_ui_status('', :ok)).
                                         and_return(pull_request_update_response)

        post '/pt_activity_web_hook', { kind: 'comment_create_activity', primary_resources: [{ id: 11111111 }], changes: [{ new_values: { text: 'ui ok' } }] }.to_json
      end
    end
  end
end
