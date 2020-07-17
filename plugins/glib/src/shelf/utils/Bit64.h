//
// Created by gen on 6/25/2020.
//

#ifndef ANDROID_BIT64_H
#define ANDROID_BIT64_H

#include <core/core.h>
#include <core/Data.h>
#include "../gs_define.h"

namespace gs {
    CLASS_BEGIN_0_N(Bit64)

    public:
        static std::string encode(const gc::Ref<gc::Data> &data);
        static gc::Ref<gc::Data> decode(const std::string &str);

        static std::string encodeString(const std::string &str);
        static std::string decodeString(const std::string &str);

        ON_LOADED_BEGIN(cls, gc::Base)
            ADD_METHOD(cls, Bit64, encode);
            ADD_METHOD(cls, Bit64, decode);
            ADD_METHOD(cls, Bit64, encodeString);
            ADD_METHOD(cls, Bit64, decodeString);
        ON_LOADED_END

    CLASS_END
}


#endif //ANDROID_BIT64_H
