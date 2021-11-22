//
// Created by gen on 11/19/21.
//

#include <jni.h>

JavaVM* bmt_vm = NULL;
jclass bmt_pluginClass = NULL;

void bmt_sendEvent(const char *name, const char *data) {
    if (bmt_vm) {
        JNIEnv *env = NULL;
        if ((*bmt_vm)->AttachCurrentThread(bmt_vm, &env, NULL) != 0) {
        }

        if (env) {
            jmethodID method = (*env)->GetStaticMethodID(env, bmt_pluginClass, "sendEvent",
                    "(Ljava/lang/String;Ljava/lang/String;)V");

            jstring jname = (*env)->NewStringUTF(env, name);
            jstring jdata = (*env)->NewStringUTF(env, data);

            (*env)->CallStaticVoidMethod(env, bmt_pluginClass, method, jname, jdata);

            (*env)->DeleteLocalRef(env, jname);
            (*env)->DeleteLocalRef(env, jdata);

            if ((*env)->ExceptionCheck(env)) {
                (*env)->ExceptionDescribe(env);
            }

            (*bmt_vm)->DetachCurrentThread(bmt_vm);
        }
    }
}

//void bmt_

jint JNI_OnLoad(JavaVM *vm, void *reserved) {
    bmt_vm = vm;
    return JNI_VERSION_1_6;
}

void JNI_OnUnload(JavaVM *vm, void *reserved) {
    bmt_vm = NULL;
}


JNIEXPORT void JNICALL
Java_com_neo_flutter_1git_FlutterGitPlugin_setup(JNIEnv *env, jobject thiz, jclass clazz) {
    bmt_pluginClass = (*env)->NewGlobalRef(env, clazz);
}