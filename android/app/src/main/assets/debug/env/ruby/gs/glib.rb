require 'object'

module GS

  class Callback < GS::Object
    native 'gc::Callback'
    
    def initialize &block
      super
      @block = block
    end

    def _invoke args
      @block.call *args if @block
    end
    
    def inv *argv
      invoke argv
    end
  end

  class Array < GS::Object 
    native 'gc::_Array'
    include Enumerable

    def each
      for (i = 0, t = size; i < t; ++i) {
        yield get(i)
      }
    end
  end

  class Map < GS::Object 

  end
end