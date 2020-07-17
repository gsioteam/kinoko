//
// Created by Gen2 on 2019-11-21.
//

#ifndef GEN_SHELF_JSSCRIPT_H
#define GEN_SHELF_JSSCRIPT_H


#include <core/script/NativeObject.h>
#include <core/script/Script.h>
#include <core/script/ScriptClass.h>
#include <core/script/ScriptInstance.h>
#include <v8.h>
#include <functional>

#include "../script_define.h"

namespace v8 {
    template <class T>
    class FunctionCallbackInfo;
    class Value;
}

namespace gscript {

    class V8Class;
    class V8Instance;
    class V8Container;
    class V8Callback;

    class V8Script : public gc::Script {
        static bool v8_init;
        V8Container *c;
        std::string env_path;

        static std::map<std::string, v8::Local<v8::Value>(*)(V8Script *script, const std::string &path)> module_loaders;

        std::map<std::string, v8::Persistent<v8::Value, v8::CopyablePersistentTraits<v8::Value> > > caches;

        typedef std::function<void(v8::Local<v8::Context>)> SetupGlobal;
        typedef std::function<void(v8::Local<v8::Context>, v8::MaybeLocal<v8::Value> result)> GetResult;

        static void destroyCallback(const v8::FunctionCallbackInfo<v8::Value>& info);

        static void callFunction(const v8::FunctionCallbackInfo<v8::Value>& info);
        static void callStaticFunction(const v8::FunctionCallbackInfo<v8::Value>& info);

        static void callMethod(const v8::FunctionCallbackInfo<v8::Value>& info);
        static void callStaticMethod(const v8::FunctionCallbackInfo<v8::Value>& info);

        static void registerClass(const v8::FunctionCallbackInfo<v8::Value>& info);
        static void printCallback(const v8::FunctionCallbackInfo<v8::Value>& info);
        static void fatalErrorCallback(const char* location, const char* message);
        static void newObject(const v8::FunctionCallbackInfo<v8::Value>& info);

        static void requireFunction(const v8::FunctionCallbackInfo<v8::Value>& info);
        v8::Local<v8::Value> loadModule(const std::string &path);
        v8::Local<v8::Value> loadJson(const std::string &path);

        void processNewObject(v8::Local<v8::Object> &obj);

        static v8::Local<v8::Value> loadModule(V8Script *script, const std::string &path);
        static v8::Local<v8::Value> loadJson(V8Script *script, const std::string &path);

        static gc::Variant toVariant(v8::Local<v8::Context> context, const v8::Local<v8::Value> &value);
        static gc::Variant toVariant(v8::Local<v8::Context> context, const v8::Local<v8::Value> &value, std::map<int, gc::Variant> &cache);
        static v8::Local<v8::Value> toValue(v8::Local<v8::Context> context, const gc::Variant &variant);

        void runScript(const char *script,
                const SetupGlobal &setup,
                const GetResult &get_result,
                const char *filename = nullptr) const;

        friend class V8Class;
        friend class V8Callback;
        friend class V8Instance;

    protected:
        virtual gc::ScriptClass *makeClass() const;

        virtual void defineFunction(const gc::StringName &name, const gc::Callback &function);

    public:

        V8Script(const char *dir);
        ~V8Script();

        virtual gc::ScriptInstance *newBuff(const std::string &cls_name, gc::Object *target, const gc::Variant **params, int count) const;

        virtual gc::Variant runFile(const char *filepath) const;
        virtual gc::Variant runScript(const char *script, const char *filename = nullptr) const;

    };

    CLASS_BEGIN_N(V8Class, gc::ScriptClass)

        virtual gc::ScriptInstance *makeInstance() const;
        virtual void bindScriptClass();

    public:
        ~V8Class();

        virtual gc::Variant apply(const gc::StringName &name, const gc::Variant **params, int count) const;

        v8::Persistent<v8::Function> &getV8Class() const {
            return *(v8::Persistent<v8::Function> *)getScriptClass();
        }

    CLASS_END

    CLASS_BEGIN_N(V8Instance, gc::ScriptInstance)

        v8::Persistent<v8::Object, v8::CopyablePersistentTraits<v8::Object> > persistent;

        static void onDeleteCallback(const v8::WeakCallbackInfo<V8Instance>& data);

    public:
        virtual gc::Variant apply(const gc::StringName &name, const gc::Variant **params, int count);
        void setScriptInstance(v8::Isolate *isolate, const v8::Local<v8::Object> &target);
        const v8::Local<v8::Object> getScriptInstance(v8::Isolate *isolate) const {
            return persistent.Get(isolate);
        }

    CLASS_END
}


#endif //GEN_SHELF_JSSCRIPT_H
