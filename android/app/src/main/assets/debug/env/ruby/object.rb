module GS
  class Object
    @@cache = []

    def native_initialize
      p "nil init #{self.class}"
    end
    
    def method_missing name, *arg
      p name
      native_call name, arg
    end
    
    def self.method_missing name, *arg
      p "In method_missing #{name}"
      native_class_call name, arg
    end

    def self.create *args
      obj = self.new *args
      obj.native_initialize args
      obj
    end

    def _keep
      @@cache << self unless @@cache.include? self
    end

    def _release 
      @cache.delete self
    end
  end
end
