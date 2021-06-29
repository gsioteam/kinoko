//
// Created by gen on 6/25/2020.
//

#ifndef ANDROID_KEYVALUE_H
#define ANDROID_KEYVALUE_H


#include "../utils/database/Model.h"
#include "../gs_define.h"

namespace gs {
    CLASS_BEGIN_TN(KeyValue, Model, 1, KeyValue)

        DEFINE_STRING(key, Key);
        DEFINE_STRING(value, Value);

    public:
        static float version() {
            return 1;
        }
        static void registerFields() {
            Model::registerFields();
            ADD_FILED(KeyValue, key, Key, true);
            ADD_FILED(KeyValue, value, Value, false);
        }

        METHOD static void set(const std::string &key, const std::string &value);
        METHOD static std::string get(const std::string &key);

        ON_LOADED_BEGIN(cls, Model<KeyValue>)
            ADD_PROPERTY_EX(cls, key, KeyValue, getKey, setKey);
            ADD_PROPERTY_EX(cls, value, KeyValue, getValue, setValue);
            ADD_METHOD(cls, KeyValue, set);
            ADD_METHOD(cls, KeyValue, get);
        ON_LOADED_END

    CLASS_END
}


#endif //ANDROID_KEYVALUE_H
