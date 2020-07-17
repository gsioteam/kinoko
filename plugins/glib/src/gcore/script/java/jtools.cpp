//
// Created by Gen2 on 2020-04-20.
//

#include "jtools.h"
#include "JScript.h"
#include <core/Array.h>

using namespace gscript;

void JNIEnvWrap::initialize(JNIEnv *env, bool new_thread) {
    this->env = env;
    this->new_thread = new_thread;
}

JNIEnvWrap::~JNIEnvWrap() {
    if (new_thread) JScript::jVM()->DetachCurrentThread();
}
JClassWrap::JClassWrap(jclass target) {
    this->target = (jclass)JScript::env()->tar()->NewGlobalRef(target);
}
JClassWrap::~JClassWrap() {
    JScript::env()->tar()->DeleteGlobalRef(target);
}

JObject::JObject(const std::string &clsname, const variant_vector &argv, gc::Ref<gscript::JNIEnvWrap> env) {
    if (!env) {
        env = JScript::env();
    }
    JNIEnv *e = env->tar();
    jclass cls = e->FindClass(clsname.c_str());
    if (cls) {
        gc::Array arr(argv);
        jobject obj = e->CallStaticObjectMethod(JScript::base_class, JScript::new_instance, cls, JScript::instance()->toJava(env, arr));
        target = obj;
        this->env = env;
    }
}

JObject::JObject(jobject target, gc::Ref<gscript::JNIEnvWrap> env) {
    if (!env) {
        env = JScript::env();
    }
    this->target = target;
    this->env = env;
}

gc::Variant JObject::call(const char *name, const variant_vector &argv) {
    JNIEnv *e = env->tar();
    jstring jstr = e->NewStringUTF(name);
    size_t len = argv.size();
    jobjectArray objects = e->NewObjectArray(len, JScript::object_class, nullptr);
    for (int i = 0; i < len; ++i) {
        jobject obj = JScript::instance()->toJava(env, argv[i]);
        e->SetObjectArrayElement(objects, i, obj);
        e->DeleteLocalRef(obj);
    }
    jobject jret = e->CallStaticObjectMethod(JScript::base_class, JScript::call_instance, target, jstr, objects);
    e->DeleteLocalRef(jstr);
    gc::Variant var = JScript::instance()->toVariant(env, jret);
    e->DeleteLocalRef(jret);
    e->DeleteLocalRef(objects);
    return var;
}