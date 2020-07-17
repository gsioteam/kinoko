//
// Created by gen on 16/9/6.
//

#include "JClass.h"
#include "JInstance.h"
#include "JScript.h"

#include <jni.h>
#include <core/FixType.h>
#include <core/Ref.h>

using namespace gscript;
using namespace gc;

ScriptInstance *JClass::makeInstance() const {
    return new JInstance;
}

void JClass::bindScriptClass() {
}

Variant JClass::apply(const StringName &name, const Variant **params, int count) const {
    Ref<JNIEnvWrap> env = JScript::env();
    auto it = clz->methods.find(name);
    if (it != clz->methods.end()) {
        return JScript::applyStatic(env, clz->target, it->second, params, count);
    }
    return Variant::null();
}

JClass::~JClass() {
}
