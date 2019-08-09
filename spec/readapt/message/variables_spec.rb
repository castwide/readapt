RSpec.describe Readapt::Message::Variables do
  before :each do
    @debugger = double(:Debugger)
    allow(@debugger).to receive(:frame) { @frame }
    @frame = nil
  end

  it "finds local variables in frames" do
    bind = proc {
      local_variable = 'string'
      send(:binding)
    }.call
    @frame = Readapt::Frame.new(nil, bind.object_id)
    arguments = {
      'variablesReference' => bind.object_id
    }
    message = Readapt::Message::Variables.new(arguments, @debugger)
    message.run
    var = message.body[:variables].find { |v| v[:name] == :local_variable }
    expect(var[:value]).to eq('string')
    expect(var[:type]).to eq('String')
  end

  it "finds global variables" do
    arguments = {
      'variablesReference' => TOPLEVEL_BINDING.receiver.object_id
    }
    message = Readapt::Message::Variables.new(arguments, @debugger)
    message.run
    names = message.body[:variables].map do |var|
      var[:name]
    end
    expect(names.all? { |name| name.to_s.start_with?('$') }).to be(true)
  end
end
