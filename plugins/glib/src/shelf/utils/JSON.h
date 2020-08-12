//
// Created by gen on 2020/5/27.
//

#ifndef ANDROID_JSON_H
#define ANDROID_JSON_H

#include <core/Ref.h>
#include <nlohmann/json.hpp>
#include "../gs_define.h"

namespace gs {
    CLASS_BEGIN_N(JSON, gc::Object)

    public:
        static gc::Variant parse(const nlohmann::json &obj);
        static nlohmann::json serialize(const gc::Variant &variant);

//        ON_LOADED_BEGIN(cls, gc::Object)
//            ADD_METHOD(cls, JSON, parse);
//            ADD_METHOD(cls, JSON, serialize);
//        ON_LOADED_END

    CLASS_END
}


#endif //ANDROID_JSON_H
