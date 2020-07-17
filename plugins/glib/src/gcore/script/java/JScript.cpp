//
// Created by gen on 16/7/5.
//


#include <core/script/ScriptInstance.h>
#include <core/script/NativeObject.h>
#include <core/FixType.h>
#include <android/asset_manager_jni.h>
#include "JScript.h"
#include "JInstance.h"
#include "JClass.h"
#include <script/Utils.h>
#include <core/String.h>
#include <core/Array.h>
#include <core/Map.h>
#include <core/Data.h>
#include <thread>
#include "jtools.h"

#define BASE_CLASS "com/qlp/glib/Base"
#define OBJECT_CLASS "java/lang/Class"
#define MAP_CLASS "java/util/HashMap"
#define STRING_CLASS "java/lang/String"

using namespace gscript;

JScript *JScript::_instance = NULL;
JavaVM *JScript::vm = NULL;
std::map<void *, gc::Wk<JNIEnvWrap> > JScript::envs;

std::mutex JScript::mtx;
jclass JScript::base_class = NULL;
jclass JScript::map_class = NULL;
jclass JScript::object_class = NULL;
jclass JScript::string_class = NULL;
jmethodID JScript::new_instance = NULL;
jmethodID JScript::get_type = NULL;
jmethodID JScript::call_instance = NULL;
jmethodID JScript::call_static = NULL;
jmethodID JScript::create_from_native = NULL;

jmethodID JScript::from_boolean = NULL;
jmethodID JScript::from_byte = NULL;
jmethodID JScript::from_char = NULL;
jmethodID JScript::from_short = NULL;
jmethodID JScript::from_int = NULL;
jmethodID JScript::from_long = NULL;
jmethodID JScript::from_float = NULL;
jmethodID JScript::from_double = NULL;

jmethodID JScript::to_boolean = NULL;
jmethodID JScript::to_byte = NULL;
jmethodID JScript::to_char = NULL;
jmethodID JScript::to_short = NULL;
jmethodID JScript::to_int = NULL;
jmethodID JScript::to_long = NULL;
jmethodID JScript::to_float = NULL;
jmethodID JScript::to_double = NULL;

jmethodID JScript::get_ptr = NULL;

jmethodID JScript::map_put = NULL;
jmethodID JScript::map_get = NULL;
jmethodID JScript::map_keys = NULL;

static JavaVM *vm;

JClassWrap* current_class = nullptr;

ScriptClass *JScript::makeClass() const {
    return new JClass;
}

JScript *JScript::instance() {
    mtx.lock();
    if (!_instance) {
        _instance = new JScript();
    }
    mtx.unlock();
    return _instance;
}

void JScript::loadVM(JavaVM *vm) {
    JScript::vm = vm;
    Ref<JNIEnvWrap> e = JScript::env();
    JNIEnv *env = e->tar();
    base_class = (jclass)env->NewGlobalRef(env->FindClass(BASE_CLASS));
    object_class = (jclass)env->NewGlobalRef(env->FindClass(OBJECT_CLASS));
    map_class = (jclass)env->NewGlobalRef(env->FindClass(MAP_CLASS));
    string_class = (jclass)env->NewGlobalRef(env->FindClass(STRING_CLASS));
    new_instance = e->tar()->GetStaticMethodID(base_class, "newInstance", "(Ljava/lang/Class;[Ljava/lang/Object;)Ljava/lang/Object;");
    get_type = e->tar()->GetStaticMethodID(base_class, "getType", "(Ljava/lang/Object;)Ljava/lang/String;");
    call_instance = e->tar()->GetStaticMethodID(base_class, "callMethod", "(Ljava/lang/Object;Ljava/lang/String;[Ljava/lang/Object;)Ljava/lang/Object;");
    call_static = e->tar()->GetStaticMethodID(base_class, "callMethod", "(Ljava/lang/Class;Ljava/lang/String;[Ljava/lang/Object;)Ljava/lang/Object;");

    create_from_native = e->tar()->GetStaticMethodID(base_class, "create", "(Ljava/lang/Class;J)Lcom/qlp/glib/Base;");

    from_boolean = e->tar()->GetStaticMethodID(base_class, "from", "(Z)Ljava/lang/Object;");
    from_byte = e->tar()->GetStaticMethodID(base_class, "from", "(B)Ljava/lang/Object;");
    from_char = e->tar()->GetStaticMethodID(base_class, "from", "(C)Ljava/lang/Object;");
    from_short = e->tar()->GetStaticMethodID(base_class, "from", "(S)Ljava/lang/Object;");
    from_int = e->tar()->GetStaticMethodID(base_class, "from", "(I)Ljava/lang/Object;");
    from_long = e->tar()->GetStaticMethodID(base_class, "from", "(J)Ljava/lang/Object;");
    from_float = e->tar()->GetStaticMethodID(base_class, "from", "(F)Ljava/lang/Object;");
    from_double = e->tar()->GetStaticMethodID(base_class, "from", "(D)Ljava/lang/Object;");

    to_boolean = e->tar()->GetStaticMethodID(base_class, "to_z", "(Ljava/lang/Object;)Z");
    to_byte = e->tar()->GetStaticMethodID(base_class, "to_b", "(Ljava/lang/Object;)B");
    to_char = e->tar()->GetStaticMethodID(base_class, "to_c", "(Ljava/lang/Object;)C");
    to_short = e->tar()->GetStaticMethodID(base_class, "to_s", "(Ljava/lang/Object;)S");
    to_int = e->tar()->GetStaticMethodID(base_class, "to_i", "(Ljava/lang/Object;)I");
    to_long = e->tar()->GetStaticMethodID(base_class, "to_j", "(Ljava/lang/Object;)J");
    to_float = e->tar()->GetStaticMethodID(base_class, "to_f", "(Ljava/lang/Object;)F");
    to_double = e->tar()->GetStaticMethodID(base_class, "to_d", "(Ljava/lang/Object;)D");

    get_ptr = e->tar()->GetMethodID(base_class, "getPtr", "()J");

    map_put = e->tar()->GetMethodID(map_class, "put", "(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;");
    map_get = e->tar()->GetMethodID(map_class, "get", "(Ljava/lang/Object;)Ljava/lang/Object;");
    map_keys = env->GetStaticMethodID(base_class, "mapKeys", "(Ljava/util/Map;)[Ljava/lang/String;");
}

gc::Ref<JNIEnvWrap> JScript::env(JNIEnv *env) {
    if (env == NULL) {
        JavaVM *vm = jVM();
        if (vm) {
            int status;

            status = vm->GetEnv((void **) &env, JNI_VERSION_1_6);
            if(status < 0) {
                pthread_t p = pthread_self();
                auto it = envs.find((void*)p);
                if (it != envs.end() && it->second) {
                    return it->second.lock();
                }
                status = vm->AttachCurrentThread(&env, NULL);
                if(status < 0) {
                    return gc::Ref<JNIEnvWrap>::null();
                }
                gc::Ref<JNIEnvWrap> ret(new_t(JNIEnvWrap, env, true));
                envs[(void*)p] = Wk<JNIEnvWrap>(ret);
                return ret;
            }
            return new_t(JNIEnvWrap, env, false);
        }
        return gc::Ref<JNIEnvWrap>::null();
    }else {
        return new_t(JNIEnvWrap, env, false);
    }
}

JScript::JScript() : Script("java") {
}

JScript::~JScript() {

}

#define ENV (env ? env : JScript::env())
jobject JScript::toJava(gc::Ref<gscript::JNIEnvWrap> env, const gc::Variant &var) {
    if (!env) env = JScript::env();
    switch (var.getType()) {
        case Variant::TypeNull: {
            return nullptr;
        }
        case Variant::TypeBool: {
            return env->tar()->CallStaticObjectMethod(base_class, from_boolean, (jboolean)var);
        }
        case Variant::TypeChar: {
            return env->tar()->CallStaticObjectMethod(base_class, from_char, (jchar)var);
        }
        case Variant::TypeShort: {
            return env->tar()->CallStaticObjectMethod(base_class, from_short, (jshort)var);
        }
        case Variant::TypeInt: {
            return env->tar()->CallStaticObjectMethod(base_class, from_int, (jint)var);
        }
        case Variant::TypeLong:
        case Variant::TypeLongLong: {
            return env->tar()->CallStaticObjectMethod(base_class, from_long, (jlong)var);
        }
        case Variant::TypeFloat: {
            return env->tar()->CallStaticObjectMethod(base_class, from_float, (jfloat)var);
        }
        case Variant::TypeDouble: {
            return env->tar()->CallStaticObjectMethod(base_class, from_double, (jdouble)var);
        }
        case Variant::TypeStringName: {
            const char *chs = var;
            return env->tar()->NewStringUTF(chs);
        }
        case Variant::TypeReference: {
            const Class *type_cls = var.getTypeClass();
            if (type_cls->isTypeOf(_String::getClass())) {
                const char *chs = var;
                return env->tar()->NewStringUTF(chs);
            } else if (type_cls->isTypeOf(_Array::getClass())) {
                Array arr = var;
                size_t len = arr.size();
                jobjectArray jarr = env->tar()->NewObjectArray(len, object_class, nullptr);
                for (int i = 0; i < len; ++i) {
                    env->tar()->SetObjectArrayElement(jarr, i, toJava(env, arr.at(i)));
                }
                return jarr;
            } else if (type_cls->isTypeOf(_Map::getClass())) {
                Map map = var;
                JObject jmap("java/util/Map", variant_vector(), env);
                for (auto it = map->begin(), _e = map->end(); it != _e; ++it) {
                    StringName key(it->first.c_str());
                    jmap.call("put", variant_vector{key, it->second});
                }
                return jmap.tar();
            } else if (type_cls->isTypeOf(Data::getClass())) {
                Ref<Data> data = var;
                size_t size = data->getSize(), offset = 0;
                jbyteArray bytes = env->tar()->NewByteArray(size);
#define BSIZE 2048
                uint8_t buf[BSIZE];
                size_t readed = 0;
                while ((readed = data->read(buf, 1, BSIZE)) > 0) {
                    env->tar()->SetByteArrayRegion(bytes, offset, readed, (const jbyte *)buf);
                    offset+=readed;
                }
                return bytes;
            } else {
                JClass* jcls = (JClass *)instance()->find(type_cls);
                if (jcls) {
                    JInstance *ins = (JInstance *)jcls->create(var.get<Object>());
                    JClassWrap *clswrap = jcls->getJavaClass();
                    JNIEnv *e = env->tar();
                    jobject jtar = e->CallStaticObjectMethod(base_class, create_from_native, clswrap->target, ins);
                    ins->setJObject(jtar, e);
                    return jtar;
                }
            }
        }
        default: return nullptr;
    }
}

gc::Variant JScript::toVariant(gc::Ref<gscript::JNIEnvWrap> env, jobject jobj, const char *type_str) {
    JNIEnv *e = env->tar();
    const char *chs;
    jstring type;
    if (type_str) {
        chs = type_str;
    } else {
        type = (jstring)e->CallStaticObjectMethod(base_class, get_type, jobj);
        chs = e->GetStringUTFChars(type, NULL);
    }
    Variant ret;
    if (chs) {
        switch (chs[0]) {
            case 'Z': {
                ret = e->CallStaticBooleanMethod(base_class, to_boolean, jobj);
                break;
            }
            case 'B': {
                ret = e->CallStaticByteMethod(base_class, to_byte, jobj);
                break;
            }
            case 'C': {
                ret = e->CallStaticCharMethod(base_class, to_char, jobj);
                break;
            }
            case 'S': {
                ret = e->CallStaticShortMethod(base_class, to_short, jobj);
                break;
            }
            case 'I': {
                ret = e->CallStaticIntMethod(base_class, to_int, jobj);
                break;
            }
            case 'J': {
                ret = e->CallStaticLongMethod(base_class, to_long, jobj);
                break;
            }
            case 'F': {
                ret = e->CallStaticFloatMethod(base_class, to_float, jobj);
                break;
            }
            case 'D': {
                ret = e->CallStaticDoubleMethod(base_class, to_double, jobj);
                break;
            }
            case '[': {
                if (chs[1] == 'B') {
                    jbyteArray bytes = (jbyteArray)jobj;
                    size_t len = e->GetArrayLength(bytes);
                    jbyte *buf = e->GetByteArrayElements(bytes, NULL);
                    Ref<Data> data = new_t(BufferData, buf, len);
                    e->ReleaseByteArrayElements(bytes, buf, 0);
                    ret = data;
                } else {
                    ret = toArray(env, jobj, chs + 1);
                }
                break;
            }
            case 'L': {
                if (e->IsInstanceOf(jobj, string_class)) {
                    jstring jstr = (jstring)jobj;
                    const char *cls_name = e->GetStringUTFChars(jstr, NULL);
                    ret = cls_name;
                    e->ReleaseStringUTFChars(jstr, cls_name);
                }else if (e->IsInstanceOf(jobj, base_class)) {
                    jlong ptr = e->CallLongMethod(jobj, get_ptr);
                    JInstance *ins = (JInstance *)ptr;
                    ret = ins->getTarget();
                } else if (e->IsInstanceOf(jobj, map_class)) {
                    Map map;
                    jobjectArray jarr = (jobjectArray)e->CallStaticObjectMethod(base_class, map_keys, jobj);
                    jsize len = e->GetArrayLength(jarr);
                    for (int i = 0; i < len; ++i) {
                        jobject jkey = e->GetObjectArrayElement(jarr, i);
                        jobject jvalue = e->CallObjectMethod(jobj, map_get, jkey);

                        if (e->IsInstanceOf(jkey, string_class) && jvalue) {
                            jstring jstr = (jstring)jkey;
                            const char *key = e->GetStringUTFChars(jstr, NULL);
                            map->set(key, toVariant(env, jvalue));
                            e->ReleaseStringUTFChars(jstr, key);
                        }
                        e->DeleteLocalRef(jkey);
                        e->DeleteLocalRef(jvalue);
                    }
                    e->DeleteLocalRef(jarr);
                    ret = map;
                }
                break;
            }
        }
    } else {

    }
    if (!type_str) {
        e->ReleaseStringUTFChars(type, chs);
        e->DeleteLocalRef(type);
    }
    return ret;
}

gc::Array JScript::toArray(gc::Ref<gscript::JNIEnvWrap> env, jobject jobj, const char *type) {
    Array arr;
    JNIEnv *e = env->tar();
    jarray array = (jarray)jobj;
    int len = e->GetArrayLength(array);
    switch (type[0]) {
        case 'Z': {
            jboolean *barr = e->GetBooleanArrayElements((jbooleanArray)array, NULL);
            for (int i = 0; i < len; ++i) {
                arr.push_back(barr[i]);
            }
            e->ReleaseBooleanArrayElements((jbooleanArray)array, barr, 0);
            break;
        }
        case 'B': {
            jbyte *barr = e->GetByteArrayElements((jbyteArray)array, NULL);
            for (int i = 0; i < len; ++i) {
                arr.push_back(barr[i]);
            }
            e->ReleaseByteArrayElements((jbyteArray)array, barr, 0);
            break;
        }
        case 'C': {
            jchar *barr = e->GetCharArrayElements((jcharArray)array, NULL);
            for (int i = 0; i < len; ++i) {
                arr.push_back(barr[i]);
            }
            e->ReleaseCharArrayElements((jcharArray)array, barr, 0);
            break;
        }
        case 'S': {
            jshort *barr = e->GetShortArrayElements((jshortArray)array, NULL);
            for (int i = 0; i < len; ++i) {
                arr.push_back(barr[i]);
            }
            e->ReleaseShortArrayElements((jshortArray)array, barr, 0);
            break;
        }
        case 'I': {
            jint *barr = e->GetIntArrayElements((jintArray)array, NULL);
            for (int i = 0; i < len; ++i) {
                arr.push_back(barr[i]);
            }
            e->ReleaseIntArrayElements((jintArray)array, barr, 0);
            break;
        }
        case 'J': {
            jlong *barr = e->GetLongArrayElements((jlongArray)array, NULL);
            for (int i = 0; i < len; ++i) {
                arr.push_back(barr[i]);
            }
            e->ReleaseLongArrayElements((jlongArray)array, barr, 0);
            break;
        }
        case 'F': {
            jfloat *barr = e->GetFloatArrayElements((jfloatArray)array, NULL);
            for (int i = 0; i < len; ++i) {
                arr.push_back(barr[i]);
            }
            e->ReleaseFloatArrayElements((jfloatArray)array, barr, 0);
            break;
        }
        case 'D': {
            jdouble *barr = e->GetDoubleArrayElements((jdoubleArray)array, NULL);
            for (int i = 0; i < len; ++i) {
                arr.push_back(barr[i]);
            }
            e->ReleaseDoubleArrayElements((jdoubleArray)array, barr, 0);
            break;
        }
        case '[': {
            for (int i = 0; i < len; ++i) {
                jobject obj = e->GetObjectArrayElement((jobjectArray)array, i);
                arr.push_back(toArray(env, obj, type + 1));
            }
        }
        case 'L': {
            for (int i = 0; i < len; ++i) {
                jobject obj = e->GetObjectArrayElement((jobjectArray)array, i);
                arr.push_back(toVariant(env, obj));
            }
        }
    }
    return arr;
}

jobject JScript::newInstance(gc::Ref<JNIEnvWrap> env, jclass clz, const variant_vector &argv) {
    JNIEnv *e = env->tar();
    jobjectArray jarr = e->NewObjectArray(argv.size(), object_class, nullptr);
    for (int i = 0; i < argv.size(); ++i) {
        jobject jobj = toJava(env, argv[i]);
        e->SetObjectArrayElement(jarr, i, jobj);
        e->DeleteLocalRef(jobj);
    }
    jobject ret = e->CallStaticObjectMethod(base_class, new_instance, clz, jarr);
    e->DeleteLocalRef(jarr);
    return ret;
}

gc::Variant JScript::applyStatic(gc::Ref<gscript::JNIEnvWrap> env, jclass clz,
                                 gscript::JMethodWrap *method, const gc::Variant **params,
                                 int count) {
    Variant ret;
    if (method->is_static) {
        int size = method->argv.size();
        jvalue *argv = (jvalue *)malloc(method->argv.size());
        for (int i = 0; i < size; ++i) {
            const Variant *p = i < count?params[i]:&Variant::null();
            argv[i].l = toJava(env, *p);
        }

        JNIEnv *e = env->tar();
        const char *type = method->ret.c_str();

        switch (type[0]) {
            case '[': {
                jobject jarr = e->CallStaticObjectMethodA(base_class, call_static, argv);
                ret = toArray(env, jarr, type + 1);
                e->DeleteLocalRef(jarr);
                break;
            }
            default: {
                jobject jobj = e->CallStaticObjectMethodA(base_class, call_static, argv);
                ret = toVariant(env, jobj);
                e->DeleteLocalRef(jobj);
                break;
            }
        }
        for (int i = 0; i < size; ++i) {
            e->DeleteLocalRef(argv[i].l);
        }

    }
    return ret;
}

gc::Variant JScript::applyInstance(gc::Ref<gscript::JNIEnvWrap> env, jobject clz,
                                   gscript::JMethodWrap *method, const gc::Variant **params,
                                   int count) {
    Variant ret;
    if (method->is_static) {
        int size = method->argv.size();
        jvalue *argv = (jvalue *)malloc(method->argv.size());
        for (int i = 0; i < size; ++i) {
            const Variant *p = i < count?params[i]:&Variant::null();
            argv[i].l = toJava(env, *p);
        }

        JNIEnv *e = env->tar();
        const char *type = method->ret.c_str();

        switch (type[0]) {
            case '[': {
                jobject jarr = e->CallStaticObjectMethodA(base_class, call_instance, argv);
                ret = toArray(env, jarr, type + 1);
                e->DeleteLocalRef(jarr);
                break;
            }
            default: {
                jobject jobj = e->CallStaticObjectMethodA(base_class, call_instance, argv);
                ret = toVariant(env, jobj);
                e->DeleteLocalRef(jobj);
                break;
            }
        }
        for (int i = 0; i < size; ++i) {
            e->DeleteLocalRef(argv[i].l);
        }

    }
    return ret;
}

extern "C" {

char *stpcpy(char *dst, char const *src)
{
    size_t src_len = strlen(src);
    return (char*)memcpy(dst, src, src_len) + src_len;
}

jint JNI_OnLoad(JavaVM *vm, void *reserved) {
    JScript::loadVM(vm);
    return JNI_VERSION_1_6;
}

JNIEXPORT void JNICALL
Java_com_qlp_glib_Base_processedClass(JNIEnv *env, jclass clazz, jclass clz, jstring clz_name) {
    const char *str_name = env->GetStringUTFChars(clz_name, nullptr);
    StringName cls_name(str_name);
    JScript *script = JScript::instance();
    JClass *cls = (JClass *)script->find(cls_name);
    if (!cls) {
        jclass jcls = (jclass)env->NewGlobalRef(clz);
        JClassWrap *cls_wrap = new JClassWrap(jcls);
        cls = (JClass *)script->regClass(cls_wrap, cls_name);
    }
    current_class = cls->getJavaClass();
    env->ReleaseStringUTFChars(clz_name, str_name);
}

JNIEXPORT void JNICALL
Java_com_qlp_glib_Base_processedMethod(JNIEnv *env, jclass clazz, jclass clz, jstring original_name,
                                     jstring name, jobjectArray argv, jstring ret, jboolean is_static) {
    const char *ori_name = env->GetStringUTFChars(original_name, nullptr);
    const char *str_name = env->GetStringUTFChars(name, nullptr);
    const char *ret_str = env->GetStringUTFChars(ret, nullptr);

    if (current_class) {
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
            mwrap->target = env->GetStaticMethodID(clz, ori_name, sig.c_str());
        } else {
            mwrap->target = env->GetMethodID(clz, ori_name, sig.c_str());
        }

        mwrap->ret = ret_str;
        current_class->methods[str_name] = mwrap;
    }

    env->ReleaseStringUTFChars(original_name, ori_name);
    env->ReleaseStringUTFChars(name, str_name);
    env->ReleaseStringUTFChars(ret, ret_str);
}

JNIEXPORT jlong JNICALL
Java_com_qlp_glib_Base_create(JNIEnv *env, jclass clazz, jstring cls_name, jobjectArray argv,
                            jobjectArray type) {
    Ref<JNIEnvWrap> _env(new_t(JNIEnvWrap, env, false));
    const char *str_name = env->GetStringUTFChars(cls_name, nullptr);
    JScript *script = JScript::instance();
    JClass *cls = (JClass *)script->find(str_name);
    jlong ret = 0;
    if (cls) {
        jsize len = env->GetArrayLength(argv);
        vector<Variant> arr;
        vector<Variant*> vs;
        for (int i = 0; i < len; ++i) {
            jobject obj = env->GetObjectArrayElement(argv, i);
            arr.push_back(JScript::toVariant(_env, obj));
            env->DeleteLocalRef(obj);
            vs.push_back(&arr.back());
        }

        ret = (jlong)cls->newInstance((const Variant **)vs.data(), arr.size());
    }
    env->ReleaseStringUTFChars(cls_name, str_name);
    return ret;
}

JNIEXPORT void JNICALL
Java_com_qlp_glib_Base_destroy(JNIEnv *env, jobject thiz, jlong ptr) {
    JInstance *ins = (JInstance *)ptr;
     delete ins;
}

JNIEXPORT jobject JNICALL
Java_com_qlp_glib_Base_call__JLjava_lang_String_2_3Ljava_lang_Object_2_3Ljava_lang_String_2(
        JNIEnv *env, jobject thiz, jlong ptr, jstring method, jobjectArray argv,
        jobjectArray type) {
    const char *name = env->GetStringUTFChars(method, NULL);
    JInstance *ins = (JInstance *)ptr;
    Ref<JNIEnvWrap> wrap(new_t(JNIEnvWrap, env, false));
    jsize size = env->GetArrayLength(argv);
    pointer_vector params;
    variant_vector vars;
    params.resize(size);
    vars.resize(size);
    for (int i = 0; i < size; ++i) {
        jobject jobj = env->GetObjectArrayElement(argv, i);
        jstring jtype = (jstring)env->GetObjectArrayElement(type, i);
        const char * strtype = env->GetStringUTFChars(jtype, NULL);
        vars[i] = JScript::toVariant(wrap, jobj, strtype);
        params[i] = &vars.at(i);
        env->ReleaseStringUTFChars(jtype, strtype);
        env->DeleteLocalRef(jobj);
        env->DeleteLocalRef(jtype);
    }
    jobject ret = JScript::toJava(wrap, ins->call(name, (const Variant **)params.data(), params.size()));
    env->ReleaseStringUTFChars(method, name);

    return ret;
}

JNIEXPORT jobject JNICALL
Java_com_qlp_glib_Base_call__Ljava_lang_String_2Ljava_lang_String_2_3Ljava_lang_Object_2_3Ljava_lang_String_2(
        JNIEnv *env, jclass clazz, jstring cls_name, jstring method, jobjectArray argv,
        jobjectArray type) {
    const char *strclz =env->GetStringUTFChars(cls_name, NULL);
    const char *name = env->GetStringUTFChars(method, NULL);

    JScript *script = JScript::instance();
    JClass *cls = (JClass *)script->find(strclz);

    Ref<JNIEnvWrap> wrap(new_t(JNIEnvWrap, env, false));
    jsize size = env->GetArrayLength(argv);
    pointer_vector params;
    variant_vector vars;
    params.resize(size);
    vars.resize(size);
    for (int i = 0; i < size; ++i) {
        jobject jobj = env->GetObjectArrayElement(argv, i);
        jstring jtype = (jstring)env->GetObjectArrayElement(type, i);
        const char * strtype = env->GetStringUTFChars(jtype, NULL);
        vars[i] = JScript::toVariant(wrap, jobj, strtype);
        params[i] = &vars.at(i);
        env->ReleaseStringUTFChars(jtype, strtype);
        env->DeleteLocalRef(jobj);
        env->DeleteLocalRef(jtype);
    }
    jobject ret = JScript::toJava(wrap, cls->call(name, (const Variant **)params.data(), params.size()));
    env->ReleaseStringUTFChars(cls_name, strclz);
    env->ReleaseStringUTFChars(method, name);

    return ret;
}

}