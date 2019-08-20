RSpec.describe Readapt::Message::SetBreakpoints do
  it 'sets breakpoints' do
    message = Readapt::Message::SetBreakpoints.new({
      'source' => {
        'path' => 'test.rb'
      },
      'lines' => [1]
    }, nil)
    message.run
    expect(message.body[:breakpoints]).not_to be_nil
    expect(Readapt::Breakpoints.match('test.rb', 1)).to be(true)
    expect(Readapt::Breakpoints.match('test.rb', 2)).to be(false)
  end
end
