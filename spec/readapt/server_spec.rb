RSpec.describe Readapt::Server do
  it 'shuts down gracefully for dead target processes' do
    expect {
      stdin, stdout, stderr, thr = Open3.popen3('ruby', 'gets.rb')
      Readapt::Server.target_in = stdin
      object = Object.new
      object.define_singleton_method :close do; end # Mock method
      object.extend Readapt::Server
      Process.kill "KILL", thr[:pid]
      object.receiving "A late message"
    }.not_to raise_error
  end

  it 'shuts down gracefully for closed target stdin' do
    expect {
      stdin, stdout, stderr, thr = Open3.popen3('ruby', File.join('spec', 'fixtures', 'gets.rb'))
      Readapt::Server.target_in = stdin
      object = Object.new
      object.define_singleton_method :close do; end # Mock method
      object.extend Readapt::Server
      stdin.close
      object.receiving "A late message"
      Process.kill "KILL", thr[:pid]
    }.not_to raise_error
  end
end
