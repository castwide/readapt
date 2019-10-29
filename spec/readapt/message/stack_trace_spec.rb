RSpec.describe Readapt::Message::StackTrace do
  it 'gets stack traces' do
    Readapt::Monitor.start __FILE__ do
      debugger = double(:Debugger)
      allow(debugger).to receive(:thread) { Readapt::Thread.find(Thread.current.object_id) }
      arguments = {}
      message = Readapt::Message::StackTrace.new(arguments, debugger)
      message.run
      expect(message.body[:stackFrames]).to be_a(Array)
      expect(message.body[:stackFrames].first[:source][:path]).to eq(__FILE__)
    end
  end
end
