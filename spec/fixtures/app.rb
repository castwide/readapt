class Foo
  def bar
    @bar ||= 'bar'
  end
end
Foo.new.bar
