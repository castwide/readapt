class TestCVar
  @@cvar = 'cvar'
end

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
    @frame = Readapt::Frame.new(nil, 0, nil, bind.object_id)
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

  it 'finds instance variables' do
    klass = Class.new do
      define_method :initialize do
        @ivar = 'ivar'
      end
    end
    object = klass.new
    arguments = {
      'variablesReference' => object.object_id
    }
    message = Readapt::Message::Variables.new(arguments, @debugger)
    message.run
    var = message.body[:variables].find { |v| v[:name] == :@ivar }
    expect(var[:value]).to eq('ivar')
    expect(var[:type]).to eq('String')
  end

  it 'finds class variables' do
    object = TestCVar.new
    arguments = {
      'variablesReference' => object.object_id
    }
    message = Readapt::Message::Variables.new(arguments, @debugger)
    message.run
    var = message.body[:variables].find { |v| v[:name] == :@@cvar }
    expect(var[:value]).to eq('cvar')
    expect(var[:type]).to eq('String')
  end

  it 'returns nil for unknown references' do
    # @todo I am not certain that this object ID will always be invalid.
    arguments = {
      'variablesReference' => 100
    }
    message = Readapt::Message::Variables.new(arguments, @debugger)
    message.run
    expect(message.body[:variables]).to be_empty
  end

  it 'finds array elements' do
    object = ['one']
    arguments = {
      'variablesReference' => object.object_id
    }
    message = Readapt::Message::Variables.new(arguments, @debugger)
    message.run
    var = message.body[:variables].first
    expect(var[:name]).to eq('[0]')
    expect(var[:value]).to eq('one')
    expect(var[:type]).to eq('String')
  end

  it 'finds hash elements' do
    object = {'one' => 'element'}
    arguments = {
      'variablesReference' => object.object_id
    }
    message = Readapt::Message::Variables.new(arguments, @debugger)
    message.run
    var = message.body[:variables].first
    expect(var[:name]).to eq('[one]')
    expect(var[:value]).to eq('element')
    expect(var[:type]).to eq('String')
  end
end
