require "tmpdir"

RSpec.describe Readapt::Finder do
  it "finds local files" do
    program = File.absolute_path(File.join('spec', 'fixtures', 'file.rb'))
    found = Readapt::Finder.find(program)
    expect(found).to eq(program)
  end

  it "finds Ruby programs" do
    program = 'rspec'
    found = Readapt::Finder.find(program)
    expect(found).to end_with('rspec')
  end

  it 'raises an error for invalid files' do
    expect {
      Readapt::Finder.find('not_a_valid_file')
    }.to raise_error(LoadError)
  end
end
