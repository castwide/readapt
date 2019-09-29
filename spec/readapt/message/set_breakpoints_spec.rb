RSpec.describe Readapt::Message::SetBreakpoints do
  it 'sets breakpoints' do
    debugger = double(:Debugger, clear_breakpoints: nil, set_breakpoint: nil)
    message = Readapt::Message::SetBreakpoints.new({
      'source' => {
        'path' => 'test.rb'
      },
      'lines' => [1]
    }, debugger)
    message.run
    expect(message.body[:breakpoints]).not_to be_nil
    expect(Readapt::Breakpoints.match('test.rb', 1)).to be(true)
    expect(Readapt::Breakpoints.match('test.rb', 2)).to be(false)
  end
end
