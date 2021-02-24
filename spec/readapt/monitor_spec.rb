RSpec.describe Readapt::Monitor do
  it 'starts and stops' do
    expect {
      Readapt::Monitor.start "" do
        nil
      end
      x = 1
      y = 2
      Readapt::Monitor.stop
    }.not_to raise_error
  end

  it 'stops on breakpoints' do
    file = File.absolute_path(File.join('spec', 'fixtures', 'app.rb'))
    stops = 0
    Readapt::Breakpoints.set(file, [3])
    Readapt::Monitor.start file do |snapshot|
      stops += 1 if snapshot.event == :breakpoint
      snapshot.control = :continue
    end
    load file
    Readapt::Monitor.stop
    expect(stops).to eq(1)
  end

  it 'stops on StandardError' do
    file = File.absolute_path(File.join('spec', 'fixtures', 'standard-error.rb'))
    stops = 0
    Readapt::Monitor.start file do |snapshot|
      stops += 1 if snapshot.event == :raise
      snapshot.control = :continue
    end
    expect {
      load file
    }.to raise_error(StandardError)
    Readapt::Monitor.stop
    expect(stops).to eq(1)
  end

  it 'stops on RuntimeError' do
    file = File.absolute_path(File.join('spec', 'fixtures', 'runtime-error.rb'))
    stops = 0
    Readapt::Monitor.start file do |snapshot|
      stops += 1 if snapshot.event == :raise
      snapshot.control = :continue
    end
    expect {
      load file
    }.to raise_error(RuntimeError)
    Readapt::Monitor.stop
    expect(stops).to eq(1)
  end

  it 'does not stop on SystemExit' do
    file = File.absolute_path(File.join('spec', 'fixtures', 'exit.rb'))
    stops = 0
    Readapt::Monitor.start file do |snapshot|
      stops += 1 if snapshot.event == :raise
      snapshot.control = :continue
    end
    load file
    Readapt::Monitor.stop
    expect(stops).to eq(0)
  end
end
