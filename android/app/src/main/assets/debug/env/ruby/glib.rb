require 'object'

module GS

  class Callback < GS::Object
    native 'gc::_Callback'
    
    def call *argv
      invoke argv
    end

    def self.block &block
      func = FunctionCallback.create
      func.block = block
      func
    end
  end

  class FunctionCallback < Callback

    attr_accessor :block

    def _invoke args
      if @block 
        @block.call *args
      end
    end
    
  end

  class Array < GS::Object 
    native 'gc::_Array'
    include Enumerable

    def [] idx
      get idx
    end

    def << val
      push_back val
    end

    def each
      size.times do |i|
        yield get(i)
      end
    end

    def []= idx, val
      set idx, val
    end

    def last
      get(size - 1)
    end
  end

  class Map < GS::Object 
    native 'gc::_Map'
    include Enumerable

    def [] key
      get key
    end

    def []= key, value
      set key, value
    end

    def each
      keys.each do |key|
        yield key, get(key)
      end
    end
  end

  class Data < GS::Object
    native 'gc::Data'

    def to_s coding
      if coding then Encoder.decode(self, coding) else text end
    end
  end

  class Encoder < GS::Object
    native 'gs::Encoder'
  end

  class Request < GS::Object
    native 'gs::Request'

    Raw = 0,
    Mutilpart = 1
    UrlEncode = 2
  end

  class Collection < GS::Object
    native 'gs::Collection'
  end

  class GumboNode < GS::Object
    native 'gs::GumboNode'

    def querySelector selector
      arr = query selector
      if arr.size > 0 then arr[0] else nil end
    end

    alias querySelectorAll query
    alias text getText
    alias tagName getTagName
    alias parentElement parent
    alias parentNode parent

    def children
      unless _children
        _children = []
        childCount.times do |i|
          _children << childAt(i)
        end
      end
      _children
    end 
  end

  class DataItem < GS::Object
    native 'gs::DataItem'

    Book = 0
    Chapter = 1
    Header = 2
  end

  class Error < GS::Object
    native 'gs::Error'
  end

  class ScriptContext < GS::Object
    native 'gs::ScriptContext'
  end
end