//
// Created by Gen2 on 2020/5/20.
//

#include <jni.h>
#include <stdio.h>
#include <script/dart/DartScript.h>
#include "utils/database/DBMaker.h"
#include "utils/database/SQLite.h"
#include "glib.h"

using namespace gscript;
using namespace gc;
using namespace gs;

JavaVM *java_vm;

DART_EXPORT
DartScript* dart_setupLibrary(Dart_CallClass call_class, Dart_CallInstance call_instance, Dart_CreateFromNative from_native) {

    initGlib();

    DartScript *script = new DartScript();
    script->setup(call_class, call_instance, from_native);
    return script;
}

DART_EXPORT
void dart_destroyLibrary(DartScript *script) {
    delete script;
}

DART_EXPORT
void dart_postSetup(const char *path) {
    std::string root_path = path;
    gs::db::setup(new_t(gs::SQLite, root_path + "/db.sql"));

}

DART_EXPORT
void dart_setCacertPath(const char *path) {
}

DART_EXPORT
void dart_runOnMainThread() {
}

extern "C"
jint JNI_OnLoad(JavaVM *vm, void *reserved) {
    java_vm = vm;
    return JNI_VERSION_1_6;
}

extern "C" void Java_com_qlp_glib_GlibPlugin_onAttached(JNIEnv *env, jobject thiz, jobject channel) {
}

extern "C" void Java_com_qlp_glib_GlibPlugin_onDetached(JNIEnv *env, jobject thiz, jobject channel) {
}