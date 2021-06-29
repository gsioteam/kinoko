//
// Created by Gen2 on 2020-03-16.
//

#include "Object.h"
#include <mutex>
#include <map>
#include <vector>
#include <sstream>
#include <script/java/JScript.h>

using namespace gs;
using namespace std;
using namespace gc;
using namespace gscript;

namespace gs {
    JavaVM *_vm;
    mutex _mutex;
    jclass _helper;
    jmethodID _processClass;

    JClassWrap *_current = nullptr;
    map<string, JClassWrap *> _classes;
}

void ArgvList::initialize(const gc::Ref<gscript::JNIEnvWrap> &wrap) {
    this->wrap = wrap;
}

ArgvList::~ArgvList() {
    JNIEnv *env = wrap->tar();
    for (auto it = retains.begin(), _e = retains.end(); it != _e; ++it) {
        env->DeleteLocalRef(*it);
    }
}

bool JavaObject::newInstance(const char *javaclass, const variant_vector &argv) {
    lock_guard<mutex> guard(_mutex);

    Ref<JNIEnvWrap> wrap = JScript::env();
    JNIEnv* env = wrap->tar();
    JClassWrap *bridgeClass;
    string clzname = javaclass;
    auto it = _classes.find(clzname);
    if (it == _classes.end()) {
        jclass jclz = env->FindClass(clzname.c_str());
        _current = new JClassWrap(jclz);
        env->CallStaticVoidMethod(_helper, _processClass, jclz);
        env->DeleteLocalRef(jclz);
        _classes[clzname] = _current;
        bridgeClass = _current;
    } else {
        bridgeClass = it->second;
    }

    bridge = bridgeClass;
    jobject loc = JScript::newInstance(wrap, bridgeClass->target, argv);
    jobj = env->NewGlobalRef(loc);
    env->DeleteLocalRef(loc);

    return true;
}

JavaObject::~JavaObject() {
    Ref<JNIEnvWrap> wrap = JScript::env();
    wrap->tar()->DeleteGlobalRef(jobj);
}

gc::Ref<ArgvList> JavaObject::makeJavaArgv(const Ref<JNIEnvWrap> &wrap, const variant_vector &vs,
                                         const std::vector<std::string> &types) {
    JNIEnv *env = wrap->tar();
    gc::Ref<ArgvList> argv(new_t(ArgvList, wrap));
    for (int i = 0, t = types.size(); i < t; ++i) {
        const std::string &type = types[i];
        const Variant &var = vs.size() > i ? vs[i] : Variant::null();
        switch (type[0]) {
            case 'Z': {
                argv->push_back(jvalue{.z = var});
                break;
            }
            case 'B': {
                argv->push_back(jvalue{.b = var});
                break;
            }
            case 'C': {
                argv->push_back(jvalue{.c = var});
                break;
            }
            case 'S': {
                argv->push_back(jvalue{.s = var});
                break;
            }
            case 'I': {
                argv->push_back(jvalue{.i = var});
                break;
            }
            case 'J': {
                argv->push_back(jvalue{.j = var});
                break;
            }
            case 'F': {
                argv->push_back(jvalue{.f = var});
                break;
            }
            case 'D': {
                argv->push_back(jvalue{.d = var});
                break;
            }
            case 'L': {
                if (type == "Ljava/lang/String;") {
                    string str = var.str();
                    jstring jstr = env->NewStringUTF(str.c_str());
                    argv->push_back(jvalue{.l = jstr});
                    argv->retain(jstr);
                } else if (var.getType() == Variant::TypeReference && var->instanceOf(JavaObject::getClass())) {
                    argv->push_back(jvalue{.l = var.get<JavaObject>()->jobj});
                } else {
                    argv->push_back(jvalue{.l = nullptr});
                }
                break;
            }
            default: {
                argv->push_back(jvalue{.l = nullptr});
                break;
            }
        }
    }
    return argv;
}

gc::Variant JavaObject::callMethod(const char *method, const variant_vector &argv) {
    Variant ret;
    auto it = bridge->methods.find(method);
    if (it != bridge->methods.end()) {
        JMethodWrap *m = it->second;
        Ref<JNIEnvWrap> wrap = JScript::env();
        JNIEnv *env = wrap->tar();
        if (m->ret.size() > 0) {
            switch (m->ret[0]) {
                case 'Z': {
                    Ref<ArgvList> av = makeJavaArgv(wrap, argv, m->argv);
                    ret = (bool)env->CallBooleanMethodA(jobj, m->target, av->list());
                    break;
                }
                case 'B': {
                    Ref<ArgvList> av = makeJavaArgv(wrap, argv, m->argv);
                    ret = env->CallByteMethodA(jobj, m->target, av->list());
                    break;
                }
                case 'C': {
                    Ref<ArgvList> av = makeJavaArgv(wrap, argv, m->argv);
                    ret = env->CallCharMethodA(jobj, m->target, av->list());
                    break;
                }
                case 'S': {
                    Ref<ArgvList> av = makeJavaArgv(wrap, argv, m->argv);
                    ret = env->CallShortMethodA(jobj, m->target, av->list());
                    break;
                }
                case 'I': {
                    Ref<ArgvList> av = makeJavaArgv(wrap, argv, m->argv);
                    ret = env->CallIntMethodA(jobj, m->target, av->list());
                    break;
                }
                case 'J': {
                    Ref<ArgvList> av = makeJavaArgv(wrap, argv, m->argv);
                    ret = env->CallLongMethodA(jobj, m->target, av->list());
                    break;
                }
                case 'F': {
                    Ref<ArgvList> av = makeJavaArgv(wrap, argv, m->argv);
                    ret = env->CallFloatMethodA(jobj, m->target, av->list());
                    break;
                }
                case 'D': {
                    Ref<ArgvList> av = makeJavaArgv(wrap, argv, m->argv);
                    ret = env->CallDoubleMethodA(jobj, m->target, av->list());
                    break;
                }
                case 'V': {
                    Ref<ArgvList> av = makeJavaArgv(wrap, argv, m->argv);
                    env->CallVoidMethodA(jobj, m->target, av->list());
                    break;
                }
                case 'L': {
                    Ref<ArgvList> av = makeJavaArgv(wrap, argv, m->argv);
                    jobject jobj = env->CallObjectMethodA(jobj, m->target, av->list());
                    if (m->ret == "Ljava/lang/String;") {
                        jstring jstr = (jstring)jobj;
                        const char *chs = env->GetStringUTFChars(jstr, NULL);
                        ret = chs;
                        env->ReleaseStringUTFChars(jstr, chs);
                    }
                    env->DeleteLocalRef(jobj);
                    break;
                }
                default: {
                    break;
                }
            }
        }
    }
    return ret;
}

extern "C" {

jint JNI_OnLoad(JavaVM *vm, void *reserved) {
    JNIEnv *env = NULL;
    vm->GetEnv((void **) &env, JNI_VERSION_1_6);
    if (env) {
        _helper = (jclass)env->NewWeakGlobalRef(env->FindClass("com/qlp/gs/Helper"));
        _processClass = env->GetStaticMethodID(_helper, "processClass", "(Ljava/lang/Class;)V");
    }
    return JNI_VERSION_1_6;
}

JNIEXPORT void JNICALL
Java_com_qlp_gs_Helper_processedMethod(JNIEnv *env, jclass clazz, jclass clz,
                                       jstring name, jobjectArray argv, jstring ret, jboolean is_static) {
    const char *str_name = env->GetStringUTFChars(name, nullptr);
    const char *ret_str = env->GetStringUTFChars(ret, nullptr);

    if (_current) {
        JMethodWrap *mwrap = new JMethodWrap();
        mwrap->is_static = is_static;

        stringstream ss;
        ss << "(";
        for (int i = 0, len = env->GetArrayLength(argv); i < len; ++i) {
            jstring jstr = (jstring)env->GetObjectArrayElement(argv, i);
            const char *chs = env->GetStringUTFChars(jstr, NULL);
            mwrap->argv.push_back(chs);
            ss << chs;
            env->ReleaseStringUTFChars(jstr, chs);
        }
        ss << ")";
        const char *strret = env->GetStringUTFChars(ret, NULL);
        mwrap->ret = strret;
        ss << strret;
        string sig = ss.str();

        if (is_static) {
            mwrap->target = env->GetStaticMethodID(clz, str_name, sig.c_str());
        } else {
            mwrap->target = env->GetMethodID(clz, str_name, sig.c_str());
        }

        mwrap->ret = ret_str;
        _current->methods[str_name] = mwrap;
    }

    env->ReleaseStringUTFChars(name, str_name);
    env->ReleaseStringUTFChars(ret, ret_str);
}

}