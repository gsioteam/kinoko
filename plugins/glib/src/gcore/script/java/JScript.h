//
// Created by gen on 16/7/5.
//

#ifndef HI_RENDER_PROJECT_ANDROID_JAVASCRIPT_H
#define HI_RENDER_PROJECT_ANDROID_JAVASCRIPT_H

#include <core/Define.h>
#include <core/script/Script.h>
#include <jni.h>
#include <string>
#include <mutex>
#include <core/Variant.h>
#include <android/asset_manager.h>
#include <core/Ref.h>
#include <core/Array.h>
#include "./jtools.h"
#include "../script_define.h"

#define JCLASS_CLASS    "java/lang/Class"
#define JSTRING_CLASS   "java/lang/String"
#define JOBJECT_CLASS   "java/lang/Object"

using namespace std;

namespace gscript {

    class JScript : public gc::Script {
    private:
        static std::mutex mtx;
        static JScript *_instance;
        static jclass base_class;
        static jclass map_class;
        static jclass object_class;
        static jclass string_class;
        static jmethodID new_instance;
        static jmethodID get_type;
        static jmethodID call_instance;
        static jmethodID call_static;

        static jmethodID create_from_native;

        static jmethodID from_boolean;
        static jmethodID from_byte;
        static jmethodID from_char;
        static jmethodID from_short;
        static jmethodID from_int;
        static jmethodID from_long;
        static jmethodID from_float;
        static jmethodID from_double;

        static jmethodID to_boolean;
        static jmethodID to_byte;
        static jmethodID to_char;
        static jmethodID to_short;
        static jmethodID to_int;
        static jmethodID to_long;
        static jmethodID to_float;
        static jmethodID to_double;

        static jmethodID get_ptr;

        static jmethodID map_put;
        static jmethodID map_get;
        static jmethodID map_keys;

        static JavaVM *vm;
        static std::map<void *, gc::Wk<JNIEnvWrap> > envs;

        static gc::Variant applyStatic(gc::Ref<JNIEnvWrap> env, jclass clz, JMethodWrap *method, const gc::Variant **params, int count);
        static gc::Variant applyInstance(gc::Ref<JNIEnvWrap> env, jobject clz, JMethodWrap *method, const gc::Variant **params, int count);

        inline static JavaVM *jVM() {return vm;}

        friend class JNIEnvWrap;
        friend class JObject;
        friend class JClass;
        friend class JInstance;
    protected:
        virtual gc::ScriptClass *makeClass() const;
        virtual void defineFunction(const gc::StringName &name, const gc::Callback &function) {}

    public:
        static gc::Variant toVariant(gc::Ref<JNIEnvWrap> env, jobject jobj, const char *type = nullptr);
        static jobject toJava(gc::Ref<JNIEnvWrap> env, const gc::Variant &var);
        static gc::Array toArray(gc::Ref<JNIEnvWrap> env, jobject jobj, const char *type);
        static jobject newInstance(gc::Ref<JNIEnvWrap> env, jclass clz, const variant_vector &argv);

        static void loadVM(JavaVM *vm);

        static gc::Ref<JNIEnvWrap> env(JNIEnv *env = nullptr);

        virtual gc::Variant runScript(const char *script, const char *filename = nullptr) const {return gc::Variant::null();};

        JScript();
        ~JScript();
        static JScript *instance();
    };

}

#endif //HI_RENDER_PROJECT_ANDROID_JAVASCRIPT_H

