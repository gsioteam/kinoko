//
// Created by Gen2 on 2020-03-16.
//

#ifndef GSHELF_OBJECT_H
#define GSHELF_OBJECT_H


#include <jni.h>
#include <core/Variant.h>
#include <core/Ref.h>
#include <script/java/JScript.h>
#include <core/Callback.h>
#include <functional>
#include "../gs_define.h"

namespace gs {
    CLASS_BEGIN_N(ArgvList, gc::Object)
        gc::Ref<gscript::JNIEnvWrap> wrap;
        std::vector<jvalue> values;
        std::vector<jobject> retains;
    public:
        void initialize(const gc::Ref<gscript::JNIEnvWrap> &wrap);
        ~ArgvList();

        const jvalue *list() const {
            return values.data();
        }
        void push_back(jvalue val) {
            values.push_back(val);
        }
        void retain(jobject obj) {
            retains.push_back(obj);
        }

    CLASS_END

    CLASS_BEGIN_N(JavaObject, gc::Object)
        jobject jobj;
        gscript::JClassWrap *bridge;
        bool newInstance(const char *javaclass, const variant_vector &argv = variant_vector());

        static gc::Ref<ArgvList> makeJavaArgv(const gc::Ref<gscript::JNIEnvWrap> &wrap, const variant_vector &vs, const std::vector<std::string> &types);

    public:
        virtual ~JavaObject();

        template <class T = JavaObject>
        static T *create(const char *javaclass) {
            T *obj = new T;
            if (obj->newInstance(javaclass)) {
                return obj;
            } else {
                delete obj;
                return nullptr;
            }
        }

        gc::Variant callMethod(const char *method, const variant_vector &argv = variant_vector());

    CLASS_END
}


#endif //GSHELF_OBJECT_H
