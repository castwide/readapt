RSpec.describe Readapt::Message::Evaluate do
  it 'evaluates expressions' do
    bind = proc {
      value = 1
      send(:binding)
    }.call
    @debugger = double(:Debugger)
    @frame = Readapt::Frame.new(nil, 0, bind)
    allow(@debugger).to receive(:frame) { @frame }
    arguments = {
      'expression' => '[value]'
      'frameId' => 99
    }
    message = Readapt::Message::Evaluate.new(arguments, @debugger)
    message.run
    result = message.body[:result]
    expect(result).to eq('[1]')
  end

  it 'evaluates expressions in global scope when frame unavailable' do
    bind = proc {
      value = 1
      send(:binding)
    }.call
    @debugger = double(:Debugger)
    @frame = Readapt::Frame::NULL_FRAME
    allow(@debugger).to receive(:frame) { @frame }
    arguments = {
      'expression' => '"sum is #{1 + 1}"'
    }
    message = Readapt::Message::Evaluate.new(arguments, @debugger)
    message.run
    result = message.body[:result]
    expect(result).to eq('sum is 2')
  end
end
