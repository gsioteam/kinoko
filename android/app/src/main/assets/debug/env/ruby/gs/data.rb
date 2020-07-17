require 'object'

module GS
  class Data < GS::Object
    native "gc::Data"
  end

  class FileData < GS::Object
    native "gc::FileData"
  end
end