//
// Created by Gen2 on 2019-11-21.
//

#ifndef GEN_SHELF_JSSCRIPT_H
#define GEN_SHELF_JSSCRIPT_H


#include <core/script/NativeObject.h>
#include <core/script/Script.h>
#include <core/script/ScriptClass.h>
#include <core/script/ScriptInstance.h>
#include <core/Callback.h>
#include <functional>

#include "../script_define.h"


extern "C" {
#include "quickjs_ext.h"
};

namespace gscript {

    class QuickJSCallback;

    class QuickJSScript : public gc::Script {
        JSRuntime *runtime;
        JSContext *context;
        std::string env_path;
        JSAtom native_key;
        JSAtom native_class_key;

        JSClassID data_class_id = 0;
        pointer_set callbacks;
        std::list<JSValue> temp;

        static JSValue printCallback(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv, int magic);
        static JSValue registerClass(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv);
        static JSValue newObject(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv);
        static JSValue destroyCallback(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv);
        static JSValue callFunction(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv);
        static JSValue callStaticFunction(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv);

        static gc::Variant toVariant(JSContext *ctx, JSValue value);
        gc::Variant toVariant(JSValue value) const;

        JSValue toValue(const gc::Variant &variant) const;

        static char *moduleName(JSContext *context,
                                const char *module_base_name,
                                const char *module_name,
                                void *opaque);
        static JSModuleDef *moduleLoader(JSContext *context,
                                        const char *module_name,
                                        void *opaque);
        JSValue loadModule(const char *filepath) const;

        void insertCallback(QuickJSCallback *callback);
        void removeCallback(QuickJSCallback *callback);

        friend class QuickJSInstance;
        friend class QuickJSClass;
        friend class QuickJSCallback;

    protected:
        virtual gc::ScriptClass *makeClass() const;

        virtual void defineFunction(const gc::StringName &name, const gc::Callback &function);

    public:

        QuickJSScript(const char *dir);
        ~QuickJSScript();

        virtual gc::ScriptInstance *newBuff(const std::string &cls_name, gc::Object *target, const gc::Variant **params, int count) const;

        virtual gc::Variant runFile(const char *filepath) const;
        virtual gc::Variant runScript(const char *script, const char *filename = nullptr) const;

        void Step();

    };

    CLASS_BEGIN_N(QuickJSClass, gc::ScriptClass)

        JSValue value;

        virtual gc::ScriptInstance *makeInstance() const;
        virtual void bindScriptClass();

        static JSValue callStatic(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv, int magic, JSValue *func_data);
        static JSValue callMember(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv, int magic, JSValue *func_data);

        friend class QuickJSScript;

    public:
        ~QuickJSClass();

        virtual gc::Variant apply(const gc::StringName &name, const gc::Variant **params, int count) const;


    CLASS_END

    CLASS_BEGIN_N(QuickJSInstance, gc::ScriptInstance)

        JSValue data;
        JSObject *object;

        static void finalizer(JSRuntime *rt, JSValue val);

    public:
        ~QuickJSInstance();

        static QuickJSInstance *GetInstance(JSContext *context, JSValue value);

        virtual gc::Variant apply(const gc::StringName &name, const gc::Variant **params, int count);
        void setScriptValue(JSContext *ctx, JSValue value);
        JSValue getScriptValue();

    CLASS_END

    CLASS_BEGIN_N(QuickJSCallback, gc::_Callback)
        QuickJSScript *script;
        JSValue value;

    public:

        void clear();
        virtual gc::Variant invoke(const gc::Array &params);

        virtual void initialize(QuickJSScript *script, JSValue value);

        ~QuickJSCallback();

    CLASS_END
}


#endif //GEN_SHELF_JSSCRIPT_H
