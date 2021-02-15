//
// Created by Gen2 on 2020/5/18.
//

#ifndef ANDROID_DARTSCRIPT_H
#define ANDROID_DARTSCRIPT_H

#include <core/script/Script.h>
#include <core/script/ScriptClass.h>
#include <core/script/ScriptInstance.h>
#include "../script_define.h"


#define DART_EXPORT extern "C" __attribute__((visibility("default"))) __attribute__((used))

namespace gscript {

    CLASS_BEGIN_N(DartInstance, gc::ScriptInstance)

    public:
        gc::Variant apply(const gc::StringName &name, const gc::Variant **params, int count);

    CLASS_END

    CLASS_BEGIN_N(DartClass, gc::ScriptClass)

        gc::ScriptInstance *makeInstance() const {
            return new_t(DartInstance);
        }

        void bindScriptClass();
    public:

        virtual gc::ScriptInstance *create(gc::Object *target) const;

        gc::Variant apply(const gc::StringName &name, const gc::Variant **params, int count) const;

    CLASS_END

    struct NativeTarget;
    typedef void (*Dart_CallClass)(const DartClass *cls, const char *name, NativeTarget *params, int length, NativeTarget *result);
    typedef void (*Dart_CallInstance)(const DartInstance *cls, const char *name, NativeTarget *params, int length, NativeTarget *result);
    typedef int (*Dart_CreateFromNative)(const DartClass *cls, const DartInstance *ins);

    class DartScript : public gc::Script {

        static DartScript   *ins;

        struct {
            Dart_CallClass to_class = nullptr;
            Dart_CallInstance to_instance = nullptr;
            Dart_CreateFromNative from_native = nullptr;
        } handlers;

        friend class DartClass;
        friend class DartInstance;

    protected:
        gc::ScriptClass *makeClass() const {
            return new_t(DartClass);
        }
        void defineFunction(const gc::StringName &name, const gc::Callback &function);

    public:
        DartScript();
        ~DartScript();

        static void setup(Dart_CallClass callClass, Dart_CallInstance callInstance, Dart_CreateFromNative createFromNative);
        static void destroy();
        static DartScript* instance();

        static bool alive();

        gc::Variant runScript(const char *script, const char *filename = nullptr) const;


    };

}

#endif //ANDROID_DARTSCRIPT_H
