RSpec.describe Readapt::Monitor do
  it 'starts and stops' do
    expect {
      Readapt::Monitor.start do
        nil
      end
      x = 1
      y = 2
      Readapt::Monitor.stop
    }.not_to raise_error
  end
end
