require 'spec_helper'

describe 'Sinatra Application' do
  def app
    Sinatra::Application
  end

  let(:logger) { instance_spy('Logger') }

  before do
    allow(Logger).to receive(:new).with(any_args).and_return(logger)
  end

  describe 'GET /' do
    it "says '200'" do
      get '/'
      expect(last_response.body).to eq('200')
    end
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
        expect(@pull_requests_ns).to receive(:update).
                                         with('github_user', 'github_repo', 1, body: update_ui_status('', :pending))
                                         .and_return(pull_request_update_response)

        post '/gh_webhook', { action: 'opened', number: 1, pull_request: { body: '' } }.to_json
      end
    end
  end

  describe '#ui_approval_text?' do
    it 'determines text indicates approval of ui' do
      expect(ui_approval_text?('ui ok')).to be_truthy
      expect(ui_approval_text?('I have updated...')).to be_falsey
    end
  end

  describe '#update_ui_status' do
    it 'returns text with updated ui status' do
      Timecop.freeze

      original_pr_body = "Hello world. This pull request is about\n\n"
      original_pr_body += <<-EOS.gsub(/^\s+/, '')
        ********************UI STATUS********************
        UI :hand:
        Updated at #{Time.now}
        ***********DO NOT ADD TEXT BELOW HERE************
      EOS

      expected_pr_body = "Hello world. This pull request is about\n\n"
      expected_pr_body += <<-EOS.gsub(/^\s+/, '')
        ********************UI STATUS********************
        :+1:
        Updated at #{Time.now}
        ***********DO NOT ADD TEXT BELOW HERE************
      EOS

      expect(update_ui_status(original_pr_body, :ok)).to eq(expected_pr_body)
    end

    context 'pull request body does not contain ui status' do
      it 'adds ui status' do
        original_pr_body = 'Hello world. This pull request is about'

        expected_pr_body = original_pr_body + "\n\n"
        expected_pr_body += <<-EOS.gsub(/^\s+/, '')
          ********************UI STATUS********************
          :+1:
          Updated at #{Time.now}
          ***********DO NOT ADD TEXT BELOW HERE************
        EOS

        expect(update_ui_status(original_pr_body, :ok)).to eq(expected_pr_body)
      end
    end
  end
end
