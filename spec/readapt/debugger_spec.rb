RSpec.describe Readapt::Debugger do
  it 'runs a block' do
    debugger = Readapt::Debugger.new
    ran = false
    debugger.run do
      ran = true
    end
    expect(ran).to be(true)
  end
end
