//
// Created by Gen2 on 2019-11-21.
//

#include "V8Script.h"
#include <v8.h>
#include <libplatform/libplatform.h>
#include <core/Callback.h>
#include <core/Map.h>
#include <core/Data.h>
#include <core/String.h>
#include <fstream>
#include <unistd.h>
#include <pthread.h>

#include "../script_define.h"

using namespace gscript;
using namespace gc;
using namespace std;

bool V8Script::v8_init = false;

#define ISO (c->isolate)

#define NEW_ENV(NAME) \
v8::Isolate::Scope isolate_scope(ISO); \
v8::HandleScope handle_scope(ISO); \
v8::Local<v8::Context> NAME = v8::Context::New(ISO, NULL, c->global_template.Get(ISO)); \
v8::Context::Scope context_scope(NAME);\
NAME->Global()->Set(ctx, v8::String::NewFromUtf8(ISO, "global").ToLocalChecked(), c->global.Get(ISO));\
NAME->SetSecurityToken(c->context.Get(ISO)->GetSecurityToken());

#define GLB_ENV(NAME) \
v8::Isolate::Scope isolate_scope(c->isolate); \
v8::HandleScope handle_scope(c->isolate); \
v8::Local<v8::Context> NAME = c->context.Get(c->isolate); \
v8::Context::Scope context_scope(NAME);

#define ESP_ENV(NAME) \
v8::Isolate::Scope isolate_scope(c->isolate); \
v8::EscapableHandleScope handle_scope(c->isolate); \
v8::Local<v8::Context> NAME = c->context.Get(c->isolate); \
v8::Context::Scope context_scope(NAME);

#define B_SIZW 4096

namespace gscript {
    uint32_t module_counter = 0;
    map<string, v8::Local<v8::Value>(*)(V8Script *script, const std::string &path)> V8Script::module_loaders = {
            {"js", &V8Script::loadModule},
            {"json", &V8Script::loadJson},
    };

    struct V8Module {
        v8::Persistent<v8::Object> module;
        std::string path;
        uint32_t id;

        V8Module(v8::Isolate* isolate, v8::Local<v8::Object> m) : module(isolate, m), id(module_counter++) {}
    };

    class V8Container {
    public:
        v8::Isolate *isolate = NULL;
        v8::Global<v8::Context> context;
        v8::Global<v8::Private> native_key;

        v8::Global<v8::ObjectTemplate> global_template;
        v8::Global<v8::Object> global;

        v8::Persistent<v8::Function> convert;

        std::map<std::string, shared_ptr<V8Module> > modules;

        v8::Persistent<v8::Function, v8::CopyablePersistentTraits<v8::Function> > setup_global;

        long timeout_index = 0;
        int script_index = 0;

        ~V8Container() {
            if (isolate) {
                isolate->Dispose();
            }
        }

        void clear() {
            context.Reset();
            native_key.Reset();
            global_template.Reset();
            global.Reset();
            convert.Reset();
            setup_global.Reset();
        }
    };

    std::string calculatePath(const std::string &base, const std::string &path) {
        int off = 0;
        string res = base.substr(0, base.find_last_of('/'));
        while (true) {
            int tar = path.find('/', off);
            if (tar == off) {
                off = tar + 1;
                continue;
            }
            string seg = path.substr(off, tar - off);
            if (seg == "..") {
                res = res.substr(0, base.find_last_of('/'));
            } else if (seg == ".") {
            } else {
                res += "/" + seg;
            }
            if (tar < 0 || tar + 1 >= path.length()) {
                break;
            } else {
                off = tar + 1;
            }
        }
        return res;
    }

    std::shared_ptr<v8::ArrayBuffer::Allocator> array_buffer_allocator_shared;
    std::unique_ptr<v8::Platform> v8platform;
}

V8Script::V8Script(const char *dir) : Script("v8") {
    c = new V8Container;
    if (!v8_init) {
        v8platform = v8::platform::NewDefaultPlatform();
        v8::V8::InitializePlatform(v8platform.get());
        v8::V8::Initialize();
        v8_init = true;
        array_buffer_allocator_shared = std::shared_ptr<v8::ArrayBuffer::Allocator>(v8::ArrayBuffer::Allocator::NewDefaultAllocator());
    }

    v8::Isolate::CreateParams create_params;
    create_params.array_buffer_allocator_shared = array_buffer_allocator_shared;

    c->isolate = v8::Isolate::New(create_params);
    c->isolate->SetFatalErrorHandler(V8Script::fatalErrorCallback);
    c->isolate->SetData(0, this);

    v8::Isolate::Scope isolate_scope(c->isolate);
    v8::HandleScope handle_scope(c->isolate);
    v8::Local<v8::ObjectTemplate> g_temp = v8::ObjectTemplate::New(ISO);

    env_path = dir;

    g_temp->Set(ISO, "_printInfo", v8::FunctionTemplate::New(ISO, V8Script::printCallback, v8::Int32::New(ISO, 0)));
    g_temp->Set(ISO, "_printWarn", v8::FunctionTemplate::New(ISO, V8Script::printCallback, v8::Int32::New(ISO, 1)));
    g_temp->Set(ISO, "_printError", v8::FunctionTemplate::New(ISO, V8Script::printCallback, v8::Int32::New(ISO, 2)));

    g_temp->Set(ISO, "_registerClass", v8::FunctionTemplate::New(ISO, V8Script::registerClass));
    g_temp->Set(ISO, "_newObject", v8::FunctionTemplate::New(ISO, V8Script::newObject));
    g_temp->Set(ISO, "_destroyObject", v8::FunctionTemplate::New(ISO, V8Script::destroyCallback));
    g_temp->Set(ISO, "_call", v8::FunctionTemplate::New(ISO, V8Script::callFunction));
    g_temp->Set(ISO, "_callStatic", v8::FunctionTemplate::New(ISO, V8Script::callStaticFunction));

    c->global_template.Reset(ISO, g_temp);

    v8::Local<v8::Context> context = v8::Context::New(c->isolate, NULL, g_temp);
    v8::Context::Scope context_scope(context);
    c->global.Reset(ISO, context->Global());

    context->Global()->Set(context,
                           v8::String::NewFromUtf8(ISO, "global").ToLocalChecked(),
                           context->Global());

    if (env_path[env_path.size() - 1] != '/') {
        env_path += '/';
    }
    string env_file = env_path + "env.js";

    c->context = v8::Global<v8::Context>(c->isolate, context);
    c->native_key = v8::Global<v8::Private>(ISO, v8::Private::New(ISO, v8::String::NewFromUtf8(ISO, "_n").ToLocalChecked()));

    loadModule(env_file);
    v8::Local<v8::Value> res = loadModule(env_path + "convert.js");
    if (res->IsFunction()) {
        c->convert.Reset(ISO, v8::Local<v8::Function>::Cast(res));
    }
}

V8Script::~V8Script() {
    {
        GLB_ENV(ctx);
        clear();
        c->clear();
    }
    delete c;
}

v8::Local<v8::Value> V8Script::loadModule(const std::string &path) {
    ESP_ENV(ctx);
    v8::Local<v8::String> ekey = v8::String::NewFromUtf8(ISO, "exports").ToLocalChecked();
    auto it = c->modules.find(path);
    if (it == c->modules.end()) {
        FILE *file = fopen(path.c_str(), "r");
        if (file) {
            std::stringstream ss;
            ss << "(function(exports, require, module, __filename, __dirname) {\n";
            char buf[B_SIZW];
            size_t readed = 0;
            while ((readed = fread(buf, 1, B_SIZW, file)) > 0) {
                ss.write(buf, readed);
            }
            fclose(file);
            ss << "\n})";

            std::string str = ss.str();
            v8::Local<v8::String> src =
                    v8::String::NewFromUtf8(c->isolate, str.c_str(),
                                            v8::NewStringType::kNormal)
                            .ToLocalChecked();

            v8::ScriptOrigin origin(v8::String::NewFromUtf8(ISO, path.c_str()).ToLocalChecked(),
                                    v8::Integer::New(ISO, 1),
                                    v8::Integer::New(ISO, 0),
                                    v8::False(ISO),
                                    v8::Local<v8::Integer>(),
                                    v8::Local<v8::Value>(),
                                    v8::False(ISO),
                                    v8::False(ISO),
                                    v8::False(ISO));

            v8::ScriptCompiler::Source source(src, origin);
            v8::Local<v8::Script> script;
            if (v8::ScriptCompiler::Compile(ctx, &source).ToLocal(&script)) {
                v8::Local<v8::Value> val;
                if (script->Run(ctx).ToLocal(&val) && val->IsFunction()) {
                    v8::Local<v8::Object> module = v8::Object::New(ISO), exports = v8::Object::New(ISO);
                    shared_ptr<V8Module> mod(new V8Module(ISO, module));
                    mod->path = path;
                    c->modules[path] = mod;
                    module->Set(ctx, ekey, exports);
                    v8::Local<v8::Function> require = v8::Function::New(ctx, V8Script::requireFunction, v8::External::New(ISO, mod.get())).ToLocalChecked();
                    v8::Local<v8::String> filename = v8::String::NewFromUtf8(ISO, path.c_str()).ToLocalChecked();
                    int idx = path.find_last_of('/');
                    string dir = idx >= 0 ? path.substr(0, idx) : "";
                    v8::Local<v8::String> dirname = v8::String::NewFromUtf8(ISO, dir.c_str()).ToLocalChecked();
                    v8::Local<v8::Value> argv[5] {
                        exports,
                        require,
                        module,
                        filename,
                        dirname
                    };
                    v8::Function::Cast(*val)->Call(ctx, ctx->Global(), 5, argv);
                    v8::Local<v8::Value> ret;
                    if (module->Get(ctx, ekey).ToLocal(&ret)) {
                        return handle_scope.Escape(ret);
                    }
                } else {
                    char err[256];
                    sprintf(err, "Load %s failed", path.c_str());
                    ISO->ThrowException(v8::Exception::Error(v8::String::NewFromUtf8(ISO, err).ToLocalChecked()));
                }
            }
        }
    } else {
        v8::Local<v8::Object> module = it->second->module.Get(ISO);
        v8::Local<v8::Value> ret;
        if (module->Get(ctx, ekey).ToLocal(&ret)) {
            return handle_scope.Escape(ret);
        }
    }
    return handle_scope.Escape(v8::Object::New(ISO));
}

v8::Local<v8::Value> V8Script::loadJson(const std::string &path) {
    ESP_ENV(ctx);
    v8::Local<v8::String> ekey = v8::String::NewFromUtf8(ISO, "exports").ToLocalChecked();
    auto it = c->modules.find(path);
    if (it == c->modules.end()) {
        FILE *f = fopen(path.c_str(), "r");
        if (f) {
            char buf[B_SIZW];
            size_t readed;
            stringstream ss;
            while ((readed = fread(buf, 1, B_SIZW, f)) > 0) {
                ss.write(buf, readed);
            }
            fclose(f);

            string content = ss.str();

            v8::Local<v8::Object> module = v8::Object::New(ISO);
            v8::MaybeLocal<v8::Value> _json =
                    v8::JSON::Parse(ctx, v8::String::NewFromUtf8(ISO, content.c_str()).ToLocalChecked());
            v8::Local<v8::Value> json;
            if (_json.ToLocal(&json)) {
            } else {
                json = v8::Null(ISO);
            }
            module->Set(ctx, ekey, json);
            return handle_scope.Escape(json);
        }
    } else {
        v8::Local<v8::Object> module = it->second->module.Get(ISO);
        v8::Local<v8::Value> ret;
        if (module->Get(ctx, ekey).ToLocal(&ret)) {
            return handle_scope.Escape(ret);
        }
    }
    return handle_scope.Escape(v8::Object::New(ISO));
}

v8::Local<v8::Value> V8Script::loadModule(gscript::V8Script *script, const std::string &path) {
    return script->loadModule(path);
}

v8::Local<v8::Value> V8Script::loadJson(gscript::V8Script *script, const std::string &path) {
    return script->loadJson(path);
}

gc::ScriptClass* V8Script::makeClass() const {
    return new V8Class;
}

void V8Script::requireFunction(const v8::FunctionCallbackInfo<v8::Value> &info) {
    if (info.Length() > 0 && info[0]->IsString()) {
        V8Script *script = (V8Script *)info.GetIsolate()->GetData(0);
        V8Container *c = script->c;
        v8::Local<v8::String> path = v8::Local<v8::String>::Cast(info[0]);
        V8Module *mod = (V8Module *)v8::Local<v8::External>::Cast(info.Data())->Value();
        string cpath;
        cpath.resize(path->Utf8Length(ISO));
        path->WriteUtf8(ISO, (char*)cpath.data());

        string target = calculatePath(mod->path, cpath);

        string filename = target.substr(target.find_last_of('/') + 1);
        int idx = filename.find_last_of('.');
        if (idx < 0) {
            string jstr = target + ".js";
            if (access(jstr.c_str(), F_OK) == 0) {
                target = jstr;
            } else {
                jstr = target + ".json";
                if (access(jstr.c_str(), F_OK) == 0) {
                    target = jstr;
                }
            }
        }

        string ext = target.substr(target.find_last_of('.') + 1);
        auto it = module_loaders.find(ext);
        info.GetReturnValue().Set(it != module_loaders.end() ? it->second(script, target) : v8::Local<v8::Value>(v8::Undefined(ISO)));
    }
}

void V8Script::printCallback(const v8::FunctionCallbackInfo<v8::Value> &info) {
    V8Script *script = (V8Script *)info.GetIsolate()->GetData(0);
    V8Container *c = script->c;
    GLB_ENV(ctx);
#define MAX_STR_SIZE 2048
    int32_t type = v8::Int32::Cast(*info.Data())->Value();
    char chs[MAX_STR_SIZE];
    stringstream ss;

    int len = info.Length();
    for (int i = 0; i < len; ++i) {
        v8::Local<v8::Value> arg = info[i];
        v8::MaybeLocal<v8::String> _str = arg->ToString(info.GetIsolate()->GetCurrentContext());
        v8::Local<v8::String> str;
        if (_str.ToLocal(&str)) {
            str->WriteUtf8(ISO, chs, MAX_STR_SIZE);
            ss << "\n-- " << chs;
        } else {
            ss << "\n-  (Unkown)";
        }
    }
    switch (type) {
        case 0: {
            auto str = ss.str();
            LOG(i, "%s", str.c_str());
            break;
        }
        case 1: {
            auto str = ss.str();
            LOG(w, "%s", str.c_str());
            break;
        }
        case 2: {
            auto str = ss.str();
            LOG(e, "%s", str.c_str());
            break;
        }
    }
}

void V8Script::fatalErrorCallback(const char *location, const char *message) {
    LOG(e, "%s (%s)", message, location);
}

void V8Script::defineFunction(const gc::StringName &name, const gc::Callback &function) {

}

void V8Script::destroyCallback(const v8::FunctionCallbackInfo<v8::Value> &info) {
    if (info.Length() > 0 && info[0]->IsObject()) {
        V8Script *script = (V8Script *)info.GetIsolate()->GetData(0);
        V8Container *c = script->c;
        GLB_ENV(ctx);
        v8::Local<v8::Object> target = v8::Local<v8::Object>::Cast(info[0]);
        v8::Local<v8::Private> key = c->native_key.Get(ISO);
        v8::MaybeLocal<v8::Value> _val = target->GetPrivate(ctx, key);
        v8::Local<v8::Value> val;
        if (_val.ToLocal(&val) && val->IsExternal()) {
            v8::Local<v8::External> ext = v8::Local<v8::External>::Cast(val);
            V8Instance *data = (V8Instance *)ext->Value();
            target->DeletePrivate(ctx, key);
            delete data;
        }
    }
}

void V8Script::newObject(const v8::FunctionCallbackInfo<v8::Value> &info) {
    v8::Local<v8::Value> arg1 = info[0];
    v8::Local<v8::Value> arg2 = info[1];
    v8::Local<v8::Value> arg3 = info[2];

    if (arg1->IsObject() && arg2->IsString() && arg3->IsArray()) {
        v8::Local<v8::Object> obj = v8::Local<v8::Object>::Cast(arg1);
        v8::Local<v8::String> class_name = v8::Local<v8::String>::Cast(arg2);
        v8::Local<v8::Array> argv = v8::Local<v8::Array>::Cast(arg3);

        V8Script *that = (V8Script *)info.GetIsolate()->GetData(0);
        V8Container *c = that->c;

        GLB_ENV(ctx);
        string clzstr;
        clzstr.resize(class_name->Utf8Length(ISO));
        class_name->WriteUtf8(ISO, (char *)clzstr.data());
        V8Class *mcls = (V8Class *)that->find(clzstr.c_str());
        if (!mcls) {
            LOG(e, "Can not init object of type %s", clzstr.c_str());
            ISO->ThrowException(v8::Exception::Error(v8::String::NewFromUtf8(ISO, "Init object failed!").ToLocalChecked()));
            return;
        }

        size_t count = argv->Length();
        V8Instance *mins;
        if (count > 0) {
            gc::Variant *vs = new gc::Variant[count];
            const gc::Variant **ps = (const gc::Variant **)malloc(count * sizeof(gc::Variant *));
            for (int i = 0; i < count; ++i) {
                auto obj = argv->Get(ctx, i);
                v8::Local<v8::Value> val;
                vs[i] = obj.ToLocal(&val) ? toVariant(ctx, val) : Variant::null();
                ps[i] = &vs[i];
            }
            mins = (V8Instance *)mcls->newInstance(ps, count);
            delete [] vs;
            free(ps);
        }else {
            mins = (V8Instance *)mcls->newInstance(NULL, 0);
        }
        mins->setScriptInstance(ISO, obj);
        obj->SetPrivate(ctx, c->native_key.Get(ISO), v8::External::New(ISO, (void *)mins));
    }
}

void V8Script::registerClass(const v8::FunctionCallbackInfo<v8::Value> &info) {
    v8::Local<v8::Value> arg1 = info[0];
    v8::Local<v8::Value> arg2 = info[1];
    if (arg1->IsFunction() && arg2->IsString()) {
        V8Script *that = (V8Script *)info.GetIsolate()->GetData(0);
        V8Container *c = that->c;
        GLB_ENV(ctx);

        v8::Local<v8::Function> Cls = v8::Local<v8::Function>::Cast(arg1);
        v8::Local<v8::String> class_name = v8::Local<v8::String>::Cast(arg2);
        string strname;
        size_t len = class_name->Utf8Length(ISO);
        strname.resize(len);
        class_name->WriteUtf8(ISO, (char *)strname.data(), len);

        v8::Persistent<v8::Function> *clz = new v8::Persistent<v8::Function>(ISO, Cls);
        that->regClass(clz, strname.c_str());
    }
}

void V8Script::callFunction(const v8::FunctionCallbackInfo<v8::Value> &info) {
    V8Script *script = (V8Script *)info.GetIsolate()->GetData(0);
    V8Container *c = script->c;
    GLB_ENV(ctx);
    v8::Local<v8::Private> key = c->native_key.Get(ISO);
    if (info.Length() >= 2 && info[0]->IsString() && info[1]->IsArray() && !info.This().IsEmpty() && info.This()->HasPrivate(ctx, key).ToChecked()) {
        v8::Local<v8::String> name = v8::Local<v8::String>::Cast(info[0]);
        v8::Local<v8::Array> argv = v8::Local<v8::Array>::Cast(info[1]);
        v8::Local<v8::External> ext = v8::Local<v8::External>::Cast(info.This()->GetPrivate(ctx, key).ToLocalChecked());
        V8Instance *mins = (V8Instance *)ext->Value();

        string name_str;
        name_str.resize(name->Length());
        name->WriteUtf8(ISO, (char *)name_str.data());
        variant_vector vars;
        pointer_vector ptrs;
        vars.resize(argv->Length());
        ptrs.resize(argv->Length());
        for (int i = 0, t = argv->Length(); i < t; ++i) {
            v8::Local<v8::Value> ret;
            if (argv->Get(ctx, i).ToLocal(&ret)) {
                vars[i] = toVariant(ctx, ret);
                ptrs[i] = &vars[i];
            }
        }
        info.GetReturnValue().Set(toValue(ctx, mins->getTarget()->call(name_str.c_str(), ptrs)));
    } else {
        ISO->ThrowException(v8::Exception::Error(v8::String::NewFromUtf8(ISO, "Wrong arguments").ToLocalChecked()));
    }
}

void V8Script::callStaticFunction(const v8::FunctionCallbackInfo<v8::Value> &info) {
    V8Script *script = (V8Script *)info.GetIsolate()->GetData(0);
    V8Container *c = script->c;
    GLB_ENV(ctx);
    v8::Local<v8::Private> key = c->native_key.Get(ISO);
    if (info.Length() >= 2 && info[0]->IsString() && info[1]->IsArray() && !info.This().IsEmpty() && info.This()->HasPrivate(ctx, key).ToChecked()) {
        v8::Local<v8::String> name = v8::Local<v8::String>::Cast(info[0]);
        v8::Local<v8::Array> argv = v8::Local<v8::Array>::Cast(info[1]);
        v8::Local<v8::External> ext = v8::Local<v8::External>::Cast(info.This()->GetPrivate(ctx, key).ToLocalChecked());
        const V8Class *mcls = (const V8Class *)ext->Value();

        string name_str;
        name_str.resize(name->Length());
        name->WriteUtf8(ISO, (char *)name_str.data());
        variant_vector vars;
        pointer_vector ptrs;
        vars.resize(argv->Length());
        ptrs.resize(argv->Length());
        for (int i = 0, t = argv->Length(); i < t; ++i) {
            v8::Local<v8::Value> ret;
            if (argv->Get(ctx, i).ToLocal(&ret)) {
                vars[i] = toVariant(ctx, ret);
                ptrs[i] = &vars[i];
            }
        }
        Variant ret;

        info.GetReturnValue().Set(toValue(ctx, mcls->getNativeClass()->call(name_str.c_str(), nullptr, (const Variant **)ptrs.data(), ptrs.size())));
    } else {
        ISO->ThrowException(v8::Exception::Error(v8::String::NewFromUtf8(ISO, "Wrong arguments").ToLocalChecked()));
    }
}

void V8Script::callMethod(const v8::FunctionCallbackInfo<v8::Value> &info) {
    v8::Isolate *isolate = info.GetIsolate();
    V8Script *script = (V8Script *)isolate->GetData(0);
    V8Container *c = script->c;
    GLB_ENV(ctx);

    v8::Array *arr = v8::Array::Cast(*info.Data());
    v8::Local<v8::External> ex = v8::Local<v8::External>::Cast(arr->Get(ctx, 0).ToLocalChecked());
    v8::Local<v8::Boolean> is_set = v8::Local<v8::Boolean>::Cast(arr->Get(ctx, 1).ToLocalChecked());
    const Method *method = (const Method *)ex->Value();

    v8::MaybeLocal<v8::Value> maybe = info.This()->GetPrivate(ctx, c->native_key.Get(ISO));
    v8::Local<v8::Value> val;
    if (maybe.ToLocal(&val) && val->IsExternal()) {
        const V8Instance *mins = (const V8Instance *)v8::External::Cast(*val)->Value();
        size_t len = info.Length();
        variant_list vars;
        pointer_vector params;
        for (int i = 0; i < len; ++i) {
            vars.push_back(toVariant(ctx, info[i]));
            params.push_back(&vars.back());
        }
        if (len == 1 && is_set->Value()) {
            char tag_name[256];
            sprintf(tag_name, "_%s", method->name.str());
            info.This()->SetPrivate(ctx, v8::Private::New(ISO, v8::String::NewFromUtf8(ISO, tag_name).ToLocalChecked()), info[0]);
        }
        info.GetReturnValue().Set(toValue(ctx, method->call(mins->getTarget().get(), (const Variant **)params.data(), len)));
    }
}

void V8Script::callStaticMethod(const v8::FunctionCallbackInfo<v8::Value> &info) {
    v8::Isolate *isolate = info.GetIsolate();
    V8Script *script = (V8Script *)isolate->GetData(0);
    V8Container *c = script->c;
    GLB_ENV(ctx);

    v8::Array *arr = v8::Array::Cast(*info.Data());
    v8::Local<v8::External> ex = v8::Local<v8::External>::Cast(arr->Get(ctx, 0).ToLocalChecked());
    const Method *method = (const Method *)ex->Value();

    v8::MaybeLocal<v8::Value> maybe = info.This()->GetPrivate(ctx, c->native_key.Get(ISO));
    v8::Local<v8::Value> val;
    if (maybe.ToLocal(&val) && val->IsExternal()) {
        const V8Class *mcls = (const V8Class *)v8::External::Cast(*val)->Value();
        size_t len = info.Length();
        variant_list vars;
        pointer_vector params;
        for (int i = 0; i < len; ++i) {
            vars.push_back(toVariant(ctx, info[i]));
            params.push_back(&vars.back());
        }

        info.GetReturnValue().Set(toValue(ctx, mcls->call(method->getName(), (const Variant **)params.data(), len)));
    }
}

gc::Variant V8Script::toVariant(v8::Local<v8::Context> context,
                                const v8::Local<v8::Value> &value) {
    std::map<int, gc::Variant> cache;
    return toVariant(context, value, cache);
}

gc::Variant V8Script::toVariant(v8::Local<v8::Context> context, const v8::Local<v8::Value> &value, std::map<int, gc::Variant> &cache) {
    v8::Isolate *isolate = context->GetIsolate();
    V8Script *script = (V8Script *)isolate->GetData(0);
    V8Container *c = script->c;
    if (value->IsName()) {
        v8::Local<v8::String> str = value->ToString(context).ToLocalChecked();
        std::string ret;
        int size = str->Utf8Length(isolate);
        ret.resize(size);
        str->WriteUtf8(isolate, (char *)ret.data(), size);
        return ret;
    } else if (value->IsBoolean()) {
        return value->BooleanValue(isolate);
    } else if (value->IsBigInt()) {
        v8::Local<v8::BigInt> num = value->ToBigInt(context).ToLocalChecked();
        return num->Int64Value();
    } else if (value->IsNumber()) {
        v8::Local<v8::Number> num = value->ToNumber(context).ToLocalChecked();
        return num->Value();
    } else if (value->IsDate()) {
        v8::Local<v8::Object> date = value->ToObject(context).ToLocalChecked();

        v8::Local<v8::Value> val;
        if (date->Get(context, v8::String::NewFromUtf8(isolate, "getTime").ToLocalChecked()).ToLocal(&val) && val->IsFunction()) {
            v8::Function *fun = v8::Function::Cast(*val);

            v8::Local<v8::Value> val_time;
            if (fun->Call(context, date, 0, nullptr).ToLocal(&val_time)) {
                return toVariant(context, val_time);
            }
        }
    } else if (value->IsArrayBuffer()) {
        v8::ArrayBuffer *buffer = v8::ArrayBuffer::Cast(*value);
        auto contents = buffer->GetContents();
        Ref<BufferData> data(new_t(BufferData, contents.Data(), contents.ByteLength()));
        return data;
    } else if (value->IsArray()) {
        v8::Array *arr = v8::Array::Cast(*value);
        int size = arr->Length();
        Array vars;
        for (int i = 0; i < size; ++i) {
            v8::Local<v8::Value> value;
            if (arr->Get(context, i).ToLocal(&value)) {
                vars.push_back(toVariant(context, value, cache));
            }else {
                vars.push_back(Variant::null());
            }
        }
        return vars;
    } else if (value->IsFunction()) {
        v8::Local<v8::Function> convert = c->convert.Get(ISO);
        v8::Local<v8::Value> val = value;
        v8::MaybeLocal<v8::Value> _ret = convert->Call(context, context->Global(), 1, &val);
        v8::Local<v8::Value> ret;
        if (_ret.ToLocal(&ret)) {
            return toVariant(context, ret);
        } else {
            return Variant::null();
        }
    } else if (value->IsObject()) {
        v8::Local<v8::Object> obj = value->ToObject(context).ToLocalChecked();

        v8::Local<v8::Private> hkey = c->native_key.Get(isolate);
        if (obj->HasPrivate(context, hkey).ToChecked()) {
            v8::Local<v8::Value> val;
            if (obj->GetPrivate(context, hkey).ToLocal(&val) && val->IsExternal()) {
                V8Instance *mins = (V8Instance *)v8::External::Cast(*val)->Value();
                return mins->getTarget();
            }
            return Variant::null();
        }

        Map map;
        v8::Local<v8::Array> names = obj->GetOwnPropertyNames(context).ToLocalChecked();
        int size = names->Length();
        for (int i = 0; i < size; ++i) {
            v8::Local<v8::Value> name = names->Get(context, i).ToLocalChecked();
            v8::Local<v8::String> str;
            if (name->ToString(context).ToLocal(&str)) {
                std::string ret;
                int len = str->Utf8Length(isolate);
                ret.resize(len);
                str->WriteUtf8(isolate, (char *)ret.data(), len);

                v8::Local<v8::Value> v;
                if (obj->Get(context, str).ToLocal(&v)) {
                    v8::Local<v8::String> str = v->TypeOf(isolate);
                    char chs[256];
                    str->WriteUtf8(isolate, chs);
                    Variant variant;
                    if (v->IsObject()) {
                        int hash = v8::Object::Cast(*v)->GetIdentityHash();
                        auto it = cache.find(hash);
                        if (it != cache.end()) {
                            variant = it->second;
                        } else {
                            variant = toVariant(context, v, cache);
                            cache[hash] = variant;
                        }
                    } else {
                        variant = toVariant(context, v, cache);
                    }
                    map->set(ret, variant);
                }
            }
        }
        return map;
    }
    return Variant::null();
}

v8::Local<v8::Value> V8Script::toValue(v8::Local<v8::Context> context, const gc::Variant &variant) {
    v8::Isolate *isolate = context->GetIsolate();
    V8Script *script = (V8Script *)isolate->GetData(0);
    V8Container *c = script->c;

    switch (variant.getType()) {
        case Variant::TypeBool: {
            return v8::Boolean::New(isolate, variant);
        }
        case Variant::TypeChar:
        case Variant::TypeShort:
        case Variant::TypeInt:
            {
            return v8::Integer::New(isolate, variant);
        }

        case Variant::TypeLong:
        case Variant::TypeLongLong: {
            return v8::BigInt::New(isolate, variant);
        }

        case Variant::TypeFloat:
        case Variant::TypeDouble: {
            return v8::Number::New(isolate, variant);
        }

        case Variant::TypeStringName: {
            StringName name = variant;
            return v8::String::NewFromUtf8(isolate, name.str()).ToLocalChecked();
        }

        case Variant::TypeReference: {
            const Class *clz = variant.getTypeClass();
            if (clz->isTypeOf(_String::getClass())) {
                string name = variant;
                return v8::String::NewFromUtf8(isolate, name.c_str()).ToLocalChecked();
            }
            Ref<Object> obj = variant;
            V8Instance *mins = (V8Instance *)obj->findScript(script);
            if (mins) {
                return mins->getScriptInstance(isolate);
            } else {
                V8Class *mcls = (V8Class *)script->find(clz);
                if (mcls) {
                    v8::Local<v8::Function> v8Cls = mcls->getV8Class().Get(ISO);
                    v8::MaybeLocal<v8::Object> _nObj = v8Cls->NewInstance(context);
                    v8::Local<v8::Object> nObj;
                    if (_nObj.ToLocal(&nObj)) {
                        V8Instance *mins = (V8Instance *)mcls->create(variant.get<Object>());
                        mins->setScriptInstance(ISO, nObj);
                        nObj->SetPrivate(context, c->native_key.Get(ISO), v8::External::New(ISO, (void *)mins));
                        return nObj;
                    }
                }
            }
        }
    }

    return v8::Undefined(isolate);
}

ScriptInstance* V8Script::newBuff(const std::string &cls_name, gc::Object *target, const gc::Variant **params,
                                  int count) const {
    return NULL;
}

gc::Variant V8Script::runFile(const char *filepath) const {
    V8Script *script = const_cast<V8Script*>(this);
    GLB_ENV(ctx);
    v8::Local<v8::Value> val = script->loadModule(filepath);
    return script->toVariant(ctx, val);
}

gc::Variant V8Script::runScript(const char *script, const char *filename) const {
    Variant ret;
    runScript(script, nullptr, [&](v8::Local<v8::Context> ctx, v8::MaybeLocal<v8::Value> _val) {
        v8::Local<v8::Value> val;
        if (_val.ToLocal(&val)) {
            ret = toVariant(ctx, val);
        }
    }, filename);
    return ret;
}

void V8Script::runScript(const char *script, const gscript::V8Script::SetupGlobal &setup,
                                const GetResult &get_result, const char *filename) const {
    if (script) {
        GLB_ENV(ctx);

        v8::Local<v8::String> source =
                v8::String::NewFromUtf8(c->isolate, script,
                                        v8::NewStringType::kNormal)
                        .ToLocalChecked();

        v8::Local<v8::Script> s;
        v8::Local<v8::String> target_file;

        if (filename) {
            target_file = v8::String::NewFromUtf8(ISO, filename, v8::NewStringType::kNormal).ToLocalChecked();
            v8::ScriptOrigin origin(target_file);
            s = v8::Script::Compile(ctx, source, &origin).ToLocalChecked();
        } else {
            string fn = env_path + "/<inline>";
            target_file = v8::String::NewFromUtf8(ISO, fn.c_str(), v8::NewStringType::kNormal).ToLocalChecked();
            s = v8::Script::Compile(ctx, source).ToLocalChecked();
        }

        if (c->setup_global.IsEmpty()) {

        } else {
            v8::Local<v8::Function> setup_global = c->setup_global.Get(ISO);
            v8::Local<v8::Value> argv[] = {
                    target_file
            };
            setup_global->Call(ctx, ctx->Global(), 1, argv);
//            v8::Local<v8::Value> requireV;
//            if (require.ToLocal(&requireV)) {
//                ctx->Global()->Set(ctx, v8::String::NewFromUtf8(ISO, "require").ToLocalChecked(), requireV);
//            }

        }

        if (setup) {
            setup(ctx);
        }

        v8::MaybeLocal<v8::Value> res = s->Run(ctx);
        if (get_result) {
            get_result(ctx, res);
        }
    }else {
        LOG(e, "Script is null");
    }
}

V8Class::~V8Class() {
    delete (v8::Persistent<v8::Function> *)this->getScriptClass();
}

gc::ScriptInstance* V8Class::makeInstance() const {
    return new V8Instance;
}

void V8Class::bindScriptClass() {
    const V8Script *script = (const V8Script *)getScript();
    const Class *cls = getNativeClass();

    v8::Persistent<v8::Function> *persistent = (v8::Persistent<v8::Function> *)this->getScriptClass();
    V8Container *c = script->c;
    GLB_ENV(ctx);
    v8::Local<v8::Function> Cls = persistent->Get(ISO);

    v8::Local<v8::Value> val = Cls->Get(ctx, v8::String::NewFromUtf8(ISO, "prototype").ToLocalChecked()).ToLocalChecked();
    v8::Local<v8::Object> prototype = v8::Local<v8::Object>::Cast(val);

    Cls->SetPrivate(ctx, c->native_key.Get(ISO), v8::External::New(ISO, (void*)this));

    pointer_map methods = cls->getMethods();
    struct FuncData {
        v8::Local<v8::Function> func;
        v8::Local<v8::Array> data;
    };
    map<StringName, FuncData > func_cache;
    for (auto it = methods.begin(); it != methods.end(); ++it) {
        StringName name(it->first);
        const Method *method = (const Method *)it->second;

        switch (method->getType()) {
            case Method::Static: {
                v8::Local<v8::Array> data = v8::Array::New(ISO, 2);
                data->Set(ctx, 0, v8::External::New(ISO, (void*)method));
                data->Set(ctx, 1, v8::Boolean::New(ISO, false));
                v8::Local<v8::Function> fn = v8::Function::New(ctx, V8Script::callStaticMethod, data).ToLocalChecked();
                Cls->Set(ctx, v8::String::NewFromUtf8(ISO, name.str()).ToLocalChecked(), fn);
                break;
            }
            case Method::Member:
            case Method::ConstMb: {
                v8::Local<v8::Array> data = v8::Array::New(ISO, 2);
                data->Set(ctx, 0, v8::External::New(ISO, (void*)method));
                data->Set(ctx, 1, v8::Boolean::New(ISO, false));
                v8::Local<v8::Function> fn = v8::Function::New(ctx, V8Script::callMethod, data).ToLocalChecked();
                prototype->Set(ctx, v8::String::NewFromUtf8(ISO, name.str()).ToLocalChecked(), fn);
                func_cache.insert({ name, {fn, data} });
                break;
            }
        }
    }

    pointer_map properties = cls->getProperties();
    for (auto it = properties.begin(), _e = properties.end(); it != _e; ++it) {
        StringName name(it->first);
        const Property *pro = (const Property *)it->second;
        v8::Local<v8::Function> getter;
        v8::Local<v8::Function> setter;
        if (pro->getGetter()) {
            const StringName &name = pro->getGetter()->getName();
            auto it = func_cache.find(name);
            if (it != func_cache.end()) {
                FuncData &fdata = it->second;
                getter = fdata.func;
            }
        }
        if (pro->getSetter()) {
            const StringName &name = pro->getSetter()->getName();
            auto it = func_cache.find(name);
            if (it != func_cache.end()) {
                FuncData &fdata = it->second;
                setter = fdata.func;
                fdata.data->Set(ctx, 1, v8::Boolean::New(ISO, true));
            }
        }
        prototype->SetAccessorProperty(v8::String::NewFromUtf8(ISO, name.str()).ToLocalChecked(),
                                       getter, setter);
    }
}

gc::Variant V8Class::apply(const gc::StringName &name, const gc::Variant **params, int count) const {
    const V8Script *script = (const V8Script *)this->getScript();
    V8Container *c = script->c;
    GLB_ENV(ctx);
    v8::Local<v8::Function> Cls = getV8Class().Get(ISO);

    v8::MaybeLocal<v8::Value> _val = Cls->Get(ctx, v8::String::NewFromUtf8(ISO, name.str()).ToLocalChecked());
    v8::Local<v8::Value> val;
    if (_val.ToLocal(&val) && val->IsFunction()) {
        vector<v8::Local<v8::Value> > vec;
        for (int i = 0; i < count; ++i) {
            vec.push_back(V8Script::toValue(ctx, *(params[i])));
        }
        v8::MaybeLocal<v8::Value> _ret = v8::Function::Cast(*val)->Call(ctx, Cls, count, vec.data());
        v8::Local<v8::Value> ret;
        if (_ret.ToLocal(&ret)) {
            return V8Script::toVariant(ctx, ret);
        }
    }
    return Variant::null();
}

gc::Variant V8Instance::apply(const gc::StringName &name, const gc::Variant **params, int count) {
    const V8Script *script = (const V8Script *)this->getScript();
    V8Container *c = script->c;
    GLB_ENV(ctx);
    v8::Local<v8::Object> sins = this->getScriptInstance(ISO);

    v8::MaybeLocal<v8::Value> _val = sins->Get(ctx, v8::String::NewFromUtf8(ISO, name.str()).ToLocalChecked());
    v8::Local<v8::Value> val;
    if (_val.ToLocal(&val) && val->IsFunction()) {
        vector<v8::Local<v8::Value> > vec;
        for (int i = 0; i < count; ++i) {
            vec.push_back(V8Script::toValue(ctx, *(params[i])));
        }
        v8::MaybeLocal<v8::Value> _ret = v8::Function::Cast(*val)->Call(ctx, sins, count, vec.data());
        v8::Local<v8::Value> ret;
        if (_ret.ToLocal(&ret)) {
            return V8Script::toVariant(ctx, ret);
        }
    }
    return Variant::null();
}

void V8Instance::setScriptInstance(v8::Isolate *isolate, const v8::Local<v8::Object> &target) {
    persistent.Reset(isolate, target);
    persistent.SetWeak(this, V8Instance::onDeleteCallback, v8::WeakCallbackType::kFinalizer);
}

void V8Instance::onDeleteCallback(const v8::WeakCallbackInfo<V8Instance> &data) {
    delete data.GetParameter();
}