require 'gr/object'
require 'gr/callback'

class TestObject < GC::Object
  native 'TestObject'

  def call_cb
    callback.inv "InRuby"
  end

end