module GS
  class Object

    def native_initialize
      p "nil init #{self.class}"
    end
    
    def method_missing name, *arg
      p name
      native_call name, arg
    end
    
    def self.method_missing name, *arg
      p "In method_missing"
      native_class_call name, arg
    end

    def self.create
      obj = self.new
      obj.native_initialize
      obj
    end
  end
end
