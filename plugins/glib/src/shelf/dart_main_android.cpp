//
// Created by Gen2 on 2020/5/20.
//

#include <jni.h>
#include <stdio.h>
#include <script/dart/DartScript.h>
#include "utils/dart/DartPlatform.h"
#include "utils/SharedData.h"
#include "utils/database/DBMaker.h"
#include "utils/database/SQLite.h"
#include "utils/GitRepository.h"
#include "utils/Platform.h"
#include "glib.h"

using namespace gscript;
using namespace gc;
using namespace gs;

jobject flutter_channel = nullptr;
JavaVM *java_vm;
jmethodID invoke_method = nullptr;

DART_EXPORT
void dart_setupLibrary(Dart_CallClass call_class, Dart_CallInstance call_instance, Dart_CreateFromNative from_native) {

    initGlib();

    DartScript::setup(call_class, call_instance, from_native);

    gs::DartPlatform::setSendSignal(C([](){
        JNIEnv *env = nullptr;
        if (java_vm->GetEnv((void **) &env, JNI_VERSION_1_6) < 0) {
            java_vm->AttachCurrentThread(&env, NULL);
        }
        if (env) {
            jstring signal = env->NewStringUTF("sendSignal");
            env->CallVoidMethod(flutter_channel, invoke_method);
            env->DeleteLocalRef(signal);
        } else {
            LOG(e, "Send signal error.");
        }
    }));
}

DART_EXPORT
void dart_destroyLibrary() {
    DartScript::destroy();
}

DART_EXPORT
void dart_postSetup(const char *path) {
    shared::root_path = path;
    gs::db::setup(new_t(gs::SQLite, shared::root_path + "/db.sql"));
    GitRepository::setup(shared::root_path);

    gs::DartPlatform::instance();
}

DART_EXPORT
void dart_setCacertPath(const char *path) {
    GitRepository::setCacertPath(path);
}

DART_EXPORT
void dart_runOnMainThread() {
    gs::Platform::onSignal();
}

extern "C"
jint JNI_OnLoad(JavaVM *vm, void *reserved) {
    java_vm = vm;
    return JNI_VERSION_1_6;
}

extern "C" void Java_com_qlp_glib_GlibPlugin_onAttached(JNIEnv *env, jobject thiz, jobject channel) {
    flutter_channel = env->NewGlobalRef(channel);
    if (!invoke_method) {
        invoke_method = env->GetMethodID(env->GetObjectClass(channel), "sendSignal", "()V");
    }
}

extern "C" void Java_com_qlp_glib_GlibPlugin_onDetached(JNIEnv *env, jobject thiz, jobject channel) {
    if (env->IsSameObject(flutter_channel, channel)) {
        env->DeleteGlobalRef(flutter_channel);
        flutter_channel = nullptr;
    }
}

extern "C" void Java_com_qlp_glib_GlibPlugin_setDebug(JNIEnv *env, jclass thiz, jstring debug_path) {
    shared::is_debug_mode = true;
    const char *chs = env->GetStringUTFChars(debug_path, NULL);
    shared::debug_path = chs;
    env->ReleaseStringUTFChars(debug_path, chs);
}

