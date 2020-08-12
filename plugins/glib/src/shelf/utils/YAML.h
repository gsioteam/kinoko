//
// Created by gen on 8/12/2020.
//

#ifndef ANDROID_YAML_H
#define ANDROID_YAML_H

#include <core/Ref.h>
#include "../gs_define.h"

namespace gs {
    CLASS_BEGIN_N(YAML, gc::Object)

        static gc::Variant parseValue(const gc::Variant &value);

    public:

        static gc::Variant parse(const std::string &str);

    CLASS_END
}


#endif //ANDROID_YAML_H
