
const Object = require('object');

class TestObject extends Object {
    static class_name = 'TestObject';
}

let obj = TestObject.new();
obj.print();