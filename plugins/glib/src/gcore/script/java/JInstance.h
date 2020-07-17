//
// Created by gen on 16/9/6.
//

#ifndef VOIPPROJECT_JINSTANCE_H
#define VOIPPROJECT_JINSTANCE_H

#include <core/script/ScriptInstance.h>
#include <jni.h>
#include "JScript.h"
#include "../script_define.h"

using namespace gc;

namespace gscript {
    class JInstance : public ScriptInstance {
        jobject object = NULL;

    public:
        _FORCE_INLINE_ JInstance() {}
        ~JInstance() {
            if (object) {
                Ref<JNIEnvWrap> env = JScript::env();
                env->tar()->DeleteWeakGlobalRef(object);
            }
        }

        virtual Variant apply(const StringName &name, const Variant **params, int count);

        void setJObject(jobject obj, JNIEnv *env) {
            if (object) env->DeleteWeakGlobalRef(object);
            object = obj ? env->NewWeakGlobalRef(obj) : obj;
        }
        _FORCE_INLINE_ jobject getJObject() {
            return object;
        }

    };
}


#endif //VOIPPROJECT_JINSTANCE_H