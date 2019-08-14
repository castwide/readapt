RSpec.describe Readapt::Breakpoints do
  it 'matches set breakpoints' do
    Readapt::Breakpoints.set 'test.rb', [1, 3]
    expect(Readapt::Breakpoints.match('test.rb', 1)).to be(true)
    expect(Readapt::Breakpoints.match('test.rb', 2)).to be(false)
    expect(Readapt::Breakpoints.match('test.rb', 3)).to be(true)
  end

  it 'clears breakpoints on reset' do
    Readapt::Breakpoints.set 'test.rb', [1]
    Readapt::Breakpoints.set 'test.rb', []
    expect(Readapt::Breakpoints.match('test.rb', 1)).to be(false)
  end

  it 'handles files without breakpoints' do
    Readapt::Breakpoints.set 'test.rb', [1]
    expect(Readapt::Breakpoints.match('no-breakpoints.rb', 1)).to be(false)
  end
end
