require 'test_object'

$obj1 = TestObject.create

$obj1.int_value = 333

class ClassB

    def print
        p "Call ClassB"
    end

end

$obj2 = ClassB.new

def test obj
    p "#{obj.class}"
end