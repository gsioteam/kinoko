# gc
This is a c++ reflection framework. set and get attribute dynamic, callback
variable parameter, classes relationships, methods or properties from a class.

### Usage

Write C++ Class like:

        #include <core/Object.h>
        #include <core/Ref.h>

        // Define a class
        CLASS_BEGIN(TestObject, gc::RefObject)

        private:
            int int_value;

        public:

            // Define a method
            METHOD _FORCE_INLINE_ int getIntValue() {
                return int_value;
            }

            METHOD _FORCE_INLINE_ void setIntValue(int value) {
                int_value = value;
            }

            // Define a property
            PROPERTY(int_value, getIntValue, setIntValue)

        CLASS_END

Run the `process.rb`

        ruby process.rb {path to header file}

This action would generate the dynamic codes. like:

        ON_LOADED_BEGIN(cls, gc::RefObject)
            ADD_PROPERTY(cls, "int_value", ADD_METHOD(cls, TestObject, getIntValue), ADD_METHOD(cls, TestObject, setIntValue));
        ON_LOADED_END

Now, you can using the reflection functions.

        Ref<TestObject> obj(new TestObject());

        // Get class name
        printf("ClassName %s\n", obj->getClass()->getFullname().str());
        printf("ClassName %s\n", obj->getInstanceClass()->getParent()->getFullname().str());

        // Call getter and setter method dynamic.
        obj->callArgs("setIntValue", 1023);
        printf("int value is %d -> %d\n", (int)obj->call("getIntValue"), obj->getIntValue());

        // Some usage of Callback
        RCallback cb = C([](int l){
            printf("output %d\n", l);
        });

        cb(30.32);
        cb(2883, "1");
        cb("nihao");

        RCallback cb2 = C([](Object *object){
            if (object) {
                printf("output %s\n", object->getInstanceClass()->getFullname().str());
            }else {
                printf("Object is NULL\n");
            }
        });

        cb2(30.32);
        cb2(2883, obj);
        cb2("nihao");
        cb2(obj);