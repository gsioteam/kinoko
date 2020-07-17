//
// Created by Gen2 on 2020-04-20.
//

#ifndef GSHELF_JTOOLS_H
#define GSHELF_JTOOLS_H

#include <jni.h>
#include <core/Ref.h>

namespace gscript {

    class JScript;

    CLASS_BEGIN_N(JNIEnvWrap, gc::Object)

    private:
        JNIEnv *env;
        bool new_thread;

        friend class JScript;
    public:
        JNIEnvWrap() {}
        ~JNIEnvWrap();

        void initialize(JNIEnv *env, bool new_thread);

        _FORCE_INLINE_ JNIEnv *tar() {
            return env;
        }

    CLASS_END

    class JMethodWrap {
    public:
        jmethodID target;
        std::vector<std::string> argv;
        std::string ret;
        bool is_static;
    };

    class JClassWrap {
    public:
        jclass target;
        std::map<gc::StringName, JMethodWrap *> methods;

        JClassWrap(jclass target);
        ~JClassWrap();
    };

    class JObject {
        jobject target;
        gc::Ref<JNIEnvWrap> env;
    public:

        jobject tar() { return target; }

        JObject(jobject target, gc::Ref<JNIEnvWrap> env = gc::Ref<JNIEnvWrap>::null());
        JObject(const std::string &clsname, const variant_vector &argv, gc::Ref<JNIEnvWrap> env = gc::Ref<JNIEnvWrap>::null());

        gc::Variant call(const char *name, const variant_vector &argv);
    };
}


#endif //GSHELF_JTOOLS_H
