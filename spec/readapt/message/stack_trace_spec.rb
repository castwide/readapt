RSpec.describe Readapt::Message::StackTrace do
  it 'gets stack traces' do
    Readapt::Monitor.start __FILE__ do
      # Disable GC to ensure the binding does not get garbage collected
      # @todo There might be a better way to handle this. Consider holding a
      #   reference to the thread's frames in threads.c.
      GC.disable
      debugger = double(:Debugger)
      allow(debugger).to receive(:thread) { Readapt::Thread.all.first }
      arguments = {}
      message = Readapt::Message::StackTrace.new(arguments, debugger)
      message.run
      expect(message.body[:stackFrames]).to be_a(Array)
      expect(message.body[:stackFrames].first[:source][:path]).to eq(__FILE__)
      GC.enable
    end
  end
end
