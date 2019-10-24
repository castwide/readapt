RSpec.describe Readapt::Frame do
  it 'evaluates in bindings' do
    var = 'var'
    block = proc {
      binding.object_id
    }
    id = block.call
    frame = Readapt::Frame.new(nil, 0, id)
    result = frame.evaluate('var')
    expect(result).to eq(var.inspect)
  end
end
