//
// Created by gen on 7/21/2020.
//

#ifndef ANDROID_SCRIPTCONTEXT_H
#define ANDROID_SCRIPTCONTEXT_H

#include <core/Ref.h>
#include <core/script/Script.h>

namespace gs {
    CLASS_BEGIN_N(ScriptContext, gc::Object)

        long timer = 0;
        gc::Script *script = nullptr;
    public:

        void initialize(const gc::StringName &type);

        METHOD gc::Variant eval(const std::string &script);

        ~ScriptContext();

        ON_LOADED_BEGIN(cls, gc::Object)
            INITIALIZER(cls, ScriptContext, initialize);
            ADD_METHOD(cls, ScriptContext, eval);
        ON_LOADED_END

    CLASS_END
}

#endif //ANDROID_SCRIPTCONTEXT_H
