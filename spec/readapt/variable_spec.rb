RSpec.describe Readapt::Variable do
  it 'structures non-empty arrays' do
    foo = ['foo']
    var = Readapt::Variable.new('foo', foo)
    expect(var.reference).not_to eq(0)
  end
end
