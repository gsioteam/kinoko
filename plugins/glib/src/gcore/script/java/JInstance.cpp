//
// Created by gen on 16/9/6.
//


#include <core/Ref.h>
#include "JInstance.h"
#include "JScript.h"
#include "JClass.h"

using namespace gscript;


Variant JInstance::apply(const StringName &name, const Variant **params, int count) {
    Ref<JNIEnvWrap> env = JScript::env();
    JClass *jcl = (JClass *)getMiddleClass();
    JClassWrap *clz = jcl->getJavaClass();
    auto it = clz->methods.find(name);
    if (it != clz->methods.end()) {
        return JScript::applyInstance(env, object, it->second, params, count);
    }
    return Variant::null();
}