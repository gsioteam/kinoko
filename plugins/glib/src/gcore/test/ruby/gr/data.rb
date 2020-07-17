require 'object'

class Data < GC::Object
    native "gc::Data"
    
end

class FileData < GC::Object
    native "gc::FileData"
    
end
