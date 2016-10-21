# Moves test log to /log/ac-indexing/foo.log for testing. Removes it once
# test is completed.
shared_context 'log' do
  let(:id) { 'foo' }
  let(:fixture) { File.join(fixture_path, 'test_file.txt') }
  let(:log_destination) { File.join(Rails.root, "log", "ac-indexing", "#{id}.log") }

  before do
    FileUtils.cp(fixture, log_destination) # Create fake log.
  end

  after do
    FileUtils.rm(log_destination) # Delete fake log.
  end
end
