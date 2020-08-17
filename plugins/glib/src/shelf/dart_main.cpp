//
// Created by Gen2 on 2020/5/20.
//

#include <jni.h>
#include <stdio.h>
#include <script/dart/DartScript.h>
#include <core/Ref.h>
#include <core/Callback.h>
#include <core/Array.h>
#include <core/Map.h>
#include "utils/dart/DartPlatform.h"
#include "utils/Platform.h"
#include "utils/GitRepository.h"
#include "utils/dart/DartRequest.h"
#include "utils/database/DBMaker.h"
#include "utils/database/SQLite.h"
#include "models/GitLibrary.h"
#include "utils/SharedData.h"
#include "main/Context.h"
#include "main/Project.h"
#include "utils/Bit64.h"
#include "main/DataItem.h"
#include "utils/Request.h"
#include "utils/Encoder.h"
#include "utils/GumboParser.h"
#include "utils/Error.h"
#include "models/KeyValue.h"
#include "utils/ScriptContext.h"
#include "models/CollectionData.h"
#include "main/LibraryContext.h"
#include "main/Settings.h"

using namespace gscript;
using namespace gc;
using namespace gs;

jobject flutter_channel = nullptr;
JavaVM *java_vm;
jmethodID invoke_method = nullptr;

DART_EXPORT
void dart_setupLibrary(Dart_CallClass call_class, Dart_CallInstance call_instance, Dart_CreateFromNative from_native) {
    gc::ClassDB::reg<gc::_Map>();
    gc::ClassDB::reg<gc::_Array>();
    gc::ClassDB::reg<gc::_Callback>();
    gc::ClassDB::reg<gs::GitRepository>();
    ClassDB::reg<gs::DartPlatform>();
    ClassDB::reg<gs::DartRequest>();
    ClassDB::reg<gs::GitAction>();
    ClassDB::reg<gs::GitLibrary>();
    ClassDB::reg<gs::Project>();
    ClassDB::reg<gs::Bit64>();
    ClassDB::reg<gs::Context>();
    ClassDB::reg<gs::Collection>();
    ClassDB::reg<gs::DataItem>();
    ClassDB::reg<gs::Request>();
    ClassDB::reg<gs::Encoder>();
    ClassDB::reg<gs::GumboNode>();
    ClassDB::reg<gs::Error>();
    ClassDB::reg<gs::KeyValue>();
    ClassDB::reg<gs::ScriptContext>();
    ClassDB::reg<gs::CollectionData>();
    ClassDB::reg<gs::LibraryContext>();
    ClassDB::reg<gs::LibraryContext>();
    ClassDB::reg<gs::SettingItem>();

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

