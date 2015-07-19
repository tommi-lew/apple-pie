require 'spec_helper'

describe 'Helpers' do
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