//
// Created by Gen2 on 2019-11-21.
//

#include "QuickJSScript.h"
#include <core/Callback.h>
#include <core/Map.h>
#include <core/Data.h>
#include <core/String.h>
#include <fstream>
#include <unistd.h>
#include <pthread.h>
#include <sys/stat.h>

#include "../script_define.h"

using namespace gscript;
using namespace gc;
using namespace std;

namespace gscript {

    bool isWordChar(char x) {
        return (x >= 'a' && x <= 'z') || (x >= 'A' && x <= 'Z') || (x >= '0' && x <= '9') || x == '_';
    }

    bool has_export(const string &strcode) {
        static string key("export");
        float found = false;
        size_t off = 0;
        while (off < strcode.size()) {
            size_t idx = strcode.find(key, off);
            if (idx < strcode.size()) {
                bool c1 = idx == 0 || !isWordChar(strcode[idx - 1]), c2 = (idx + key.size()) == strcode.size() || !isWordChar(strcode[idx + key.size()]);
                found = c1 && c2;
                if (found) break;
            }
            off = idx < strcode.size() ? idx + key.size() : idx;
        }
        return found;
    }

    void PrintError(JSContext *context, JSValue value, const char *prefix = nullptr) {
        stringstream ss;
        const char *str = JS_ToCString(context, value);
        if (str) {
            ss << str << endl;
            JS_FreeCString(context, str);
        }

        JSValue stack = JS_GetPropertyStr(context, value, "stack");
        if (!JS_IsException(stack)) {
            str = JS_ToCString(context, stack);
            if (str) {
                ss << str << endl;
                JS_FreeCString(context, str);
            }
            JS_FreeValue(context, stack);
        }

        string output = ss.str();
        if (prefix) {
            LOG(e, "%s: %s", prefix, output.c_str());
        } else {
            LOG(e, "%s", output.c_str());
        }
    }

    std::list<std::string> split(const std::string & original, const std::string &separator )
    {
        std::list<std::string> results;
        size_t len = original.length(), offset = 0;
        while (offset < len) {
            size_t index = original.find(separator, offset);
            results.push_back(original.substr(offset, index - offset));

            if (index < len) {
                offset = index + separator.length();
            } else {
                break;
            }
        }
        return results;
    }

    string join(const list<string> &segs, const string &separator) {
        stringstream ss;
        bool first = true;
        for (auto it = segs.begin(), _e = segs.end(); it != _e; ++it) {
            if (first) {
                first = false;
            } else
                ss << separator;
            ss << *it;
        }
        return ss.str();
    }

    char *new_string(JSContext *ctx, const string &str) {
        int len = str.length();
        char *chs = (char *)js_malloc(ctx, len + 1);
        memcpy(chs, str.data(), len);
        chs[len] = 0;
        return chs;
    }
}

JSValue QuickJSScript::printCallback(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv, int magic) {
    stringstream ss;
    for (int i = 0; i < argc; ++i) {
        const char *str = JS_ToCString(ctx, argv[i]);
        ss << str << " , ";
        JS_FreeCString(ctx, str);
    }

    switch (magic) {
        case 0:{
            string str = ss.str();
            LOG(i, "%s", str.c_str());
            break;
        }
        case 1: {
            string str = ss.str();
            LOG(w, "%s", str.c_str());
            break;
        }
        case 2: {
            string str = ss.str();
            LOG(e, "%s", str.c_str());
            break;
        }
    }
    return JS_UNDEFINED;
}

JSValue QuickJSScript::registerClass(JSContext *ctx, JSValueConst this_val, int argc,
                                     JSValueConst *argv) {
    QuickJSScript *script = (QuickJSScript *)JS_GetContextOpaque(ctx);
    if (argc >= 2) {
        JSValue value = argv[0];
        const char *str = JS_ToCString(ctx, argv[1]);
        ScriptClass *mcls = script->regClass(JS_VALUE_GET_OBJ(value), str);
        JS_FreeCString(ctx, str);

        JS_SetProperty(script->context, value, script->native_class_key, JS_NewBigInt64(script->context, (int64_t)mcls));
    }
    return JS_UNDEFINED;
}

QuickJSScript::QuickJSScript(const char *dir) : Script("quickjs") {
    runtime = JS_NewRuntime();
    JS_SetModuleLoaderFunc(runtime, moduleName, moduleLoader, this);

    context = JS_NewContext(runtime);
    JS_SetRuntimeOpaque(runtime, this);
    JS_SetContextOpaque(context, this);
    JS_AddIntrinsicOperators(context);
    JS_AddIntrinsicRequire(context);

    env_path = dir;

    JSValue global = JS_GetGlobalObject(context);

    JS_SetPropertyStr(context, global, "_printInfo",
            JS_NewCFunctionMagic(
                    context,
                    printCallback,
                    "log",
                    0,
                    JS_CFUNC_generic_magic,
                    0
                    ));
    JS_SetPropertyStr(context, global, "_printWarn",
                      JS_NewCFunctionMagic(
                              context,
                              printCallback,
                              "warn",
                              0,
                              JS_CFUNC_generic_magic,
                              1
                      ));
    JS_SetPropertyStr(context, global, "_printError",
                      JS_NewCFunctionMagic(
                              context,
                              printCallback,
                              "error",
                              0,
                              JS_CFUNC_generic_magic,
                              2
                      ));

    JS_SetPropertyStr(context, global, "_registerClass",
            JS_NewCFunction(
                    context,
                    registerClass,
                    "_registerClass",
                    2));
    JS_SetPropertyStr(context, global, "_newObject",
                      JS_NewCFunction(
                              context,
                              newObject,
                              "_newObject",
                              2));
    JS_SetPropertyStr(context, global, "_destroyObject",
                      JS_NewCFunction(
                              context,
                              destroyCallback,
                              "_destroyObject",
                              1));
    JS_SetPropertyStr(context, global, "_call",
                      JS_NewCFunction(
                              context,
                              callFunction,
                              "_call",
                              2));
    JS_SetPropertyStr(context, global, "_callStatic",
                      JS_NewCFunction(
                              context,
                              callStaticFunction,
                              "_callStatic",
                              2));
    JSAtom filenameAtom = JS_NewAtom(context, "__filename");
    JSAtom dirnameAtom = JS_NewAtom(context, "__dirname");

    JS_DefinePropertyGetSet(context, global, filenameAtom,
            JS_NewCFunction(
                    context, [](JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv){
                        JSAtom atom = JS_GetScriptOrModuleName(ctx, 1);
                        JSValue val = JS_AtomToString(ctx, atom);
                        JS_FreeAtom(ctx, atom);
                        return val;
                    }, "get", 0),
                    JS_UNDEFINED, 0);


    JS_DefinePropertyGetSet(context, global, dirnameAtom,
                            JS_NewCFunction(
                                    context,
                                    [](JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv){
                                        JSAtom atom = JS_GetScriptOrModuleName(ctx, 1);
                                        JSValue val = JS_UNDEFINED;
                                        const char *chs = JS_AtomToCString(ctx, atom);
                                        if (chs) {
                                            string str = chs;
                                            JS_FreeCString(ctx, chs);
                                            int index = str.find_last_of('/');
                                            if (index >= 0) {
                                                str = str.substr(0, index);
                                            }
                                            val = JS_NewString(ctx, str.c_str());
                                        }
                                        JS_FreeAtom(ctx, atom);
                                        return val;
                                    }, "get", 0),
                            JS_UNDEFINED, 0);

    JS_FreeAtom(context, filenameAtom);
    JS_FreeAtom(context, dirnameAtom);

    JSAtom globalAtom = JS_NewAtom(context, "global");
    JS_DefinePropertyGetSet(context, global, globalAtom, JS_NewCFunction(context, [](JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv){
        return JS_GetGlobalObject(ctx);
    }, "global", 0), JS_UNDEFINED, 0);
    JS_FreeAtom(context, globalAtom);

    JS_FreeValue(context, global);

    if (env_path[env_path.size() - 1] != '/') {
        env_path += '/';
    }
    string env_file = env_path + "env.js";

    native_key = JS_NewAtom(context, "$native");
    native_class_key = JS_NewAtom(context, "$class");

    ifstream ifs(env_file);
    if (ifs.is_open()) {
        string strcode((std::istreambuf_iterator<char>(ifs)),
                       (std::istreambuf_iterator<char>()));
        runScript(strcode.c_str(), env_file.c_str());

    } else {
    }

}

QuickJSScript::~QuickJSScript() {
    for (auto it = callbacks.begin(), _e = callbacks.end(); it != _e; ++it) {
        QuickJSCallback *callback = (QuickJSCallback *)*it;
        callback->clear();
    }
    for (auto it = temp.begin(), _e = temp.end(); it != _e; ++it) {
        JS_FreeValue(context, *it);
    }
    clear();
    JS_FreeAtom(context, native_key);
    JS_FreeAtom(context, native_class_key);
    JS_FreeContext(context);
    JS_FreeRuntime(runtime);
}

void QuickJSScript::Step() {
    for (auto it = temp.begin(), _e = temp.end(); it != _e; ++it) {
        JS_FreeValue(context, *it);
    }
    temp.clear();

    while (JS_IsJobPending(runtime)) {
        JSContext *context;
        JS_ExecutePendingJob(runtime, &context);
    }
}

char* QuickJSScript::moduleName(JSContext *context, const char *module_base_name,
                                const char *module_name, void *opaque) {
    static const string dotdot(".."), dot("."), separator("/");
    std::string basename(module_base_name), modulename(module_name);
    list<string> path = split(basename, separator), segs = split(modulename, separator);
    path.pop_back();
    for (auto it = segs.begin(), _e = segs.end(); it != _e; ++it) {
        const string &seg = *it;
        if (seg.length() == 0 || seg == dot) {

        } else if (seg == dotdot) {
            path.pop_back();
        } else {
            path.push_back(seg);
        }
    }

    string fullpath = join(path, separator);

    struct stat st;
    if (stat(fullpath.c_str(), &st) == 0 && S_ISREG(st.st_mode)) {
        return new_string(context, fullpath);
    } else {
        string spath = fullpath + ".js";
        if (stat(spath.c_str(), &st) == 0 && S_ISREG(st.st_mode)) {
            return new_string(context, spath);
        } else {
            spath = fullpath + ".json";
            if (stat(spath.c_str(), &st) == 0 && S_ISREG(st.st_mode)) {
                return new_string(context, spath);
            }
        }
    }
    return nullptr;
}

JSModuleDef* QuickJSScript::moduleLoader(JSContext *context, const char *module_name,
                                         void *opaque) {
//    QuickJSScript *script = (QuickJSScript *)opaque;

    ifstream ifs(module_name);
    if (ifs.is_open()) {
        string strcode((std::istreambuf_iterator<char>(ifs)),
                       (std::istreambuf_iterator<char>()));

        JSModuleDef *module = nullptr;
        if (!has_export(strcode)) {
            stringstream ss;
            ss << "const module = {exports: {}}; let exports = module.exports;" << endl;
            ss << strcode << endl;
            ss << "export default module.exports;" << endl;
            strcode = ss.str();
        }
        JSValue val = JS_Eval(context, strcode.data(), (int)strcode.size(), module_name, JS_EVAL_TYPE_MODULE | JS_EVAL_FLAG_COMPILE_ONLY);
        if (!JS_IsException(val)) {
            module = (JSModuleDef *)JS_VALUE_GET_PTR(val);
            JS_FreeValue(context, val);
        }
        return module;
    }
    return nullptr;
}

gc::ScriptClass* QuickJSScript::makeClass() const {
    return new QuickJSClass;
}

gc::Variant QuickJSScript::runScript(const char *script, const char *filename) const {
    if (filename == nullptr) filename = "<inline>";
    string str = script;
    JSValue val = JS_Eval(context, str.data(), str.size(), filename, JS_EVAL_TYPE_GLOBAL);
    if (JS_IsException(val)) {
        JSValue ex = JS_GetException(context);
        PrintError(context, ex, "[Eval]");
        JS_FreeValue(context, ex);
        return Variant::null();
    } else {
        Variant ret = toVariant(val);
        const_cast<QuickJSScript*>(this)->temp.push_back(val);
        return ret;
    }
}

gc::Variant QuickJSScript::runFile(const char *filepath) const {
    JSValue val = loadModule(filepath);
    Variant ret = toVariant(val);
    const_cast<QuickJSScript*>(this)->temp.push_back(val);
    return ret;
}

JSValue QuickJSScript::loadModule(const char *filepath) const {
    ifstream ifs(filepath);
    if (!ifs.is_open()) return JS_UNDEFINED;
    string strcode((std::istreambuf_iterator<char>(ifs)),
                   (std::istreambuf_iterator<char>()));

    if (!has_export(strcode)) {
        stringstream ss;
        ss << "const module = {exports: {}}; let exports = module.exports;" << endl;
        ss << strcode << endl;
        ss << "export default module.exports;" << endl;
        strcode = ss.str();
    }

    JSValue ret = JS_Eval(context, strcode.c_str(), strcode.size(), filepath, JS_EVAL_TYPE_MODULE | JS_EVAL_FLAG_COMPILE_ONLY);
    if (JS_IsException(ret)) {
        JSValue ex = JS_GetException(context);
        PrintError(context, ex, "[Load]");
        JS_FreeValue(context, ex);
        return JS_UNDEFINED;
    } else {
        int tag = JS_VALUE_GET_TAG(ret);
        if (tag == JS_TAG_MODULE) {
            JSValue val = JS_EvalFunction(context, ret);
            if (JS_IsException(val)) {
                JSValue ex = JS_GetException(context);
                PrintError(context, ex, "[Load]");
                JS_FreeValue(context, ex);
                return JS_UNDEFINED;
            } else {
                JSModuleDef *module = (JSModuleDef *)JS_VALUE_GET_PTR(ret);
                JSValue data = JS_GetModuleDefault(context, module);

                JS_FreeValue(context, val);
                return data;
            }
        } else {
            return JS_UNDEFINED;
        }
    }
}

gc::ScriptInstance * QuickJSScript::newBuff(const std::string &cls_name, gc::Object *target, const gc::Variant **params, int count) const {
    return nullptr;
}

JSValue QuickJSScript::destroyCallback(JSContext *ctx, JSValueConst this_val, int argc,
                                       JSValueConst *argv) {
    if (argc >= 1) {
        const QuickJSScript *script = (const QuickJSScript *)JS_GetContextOpaque(ctx);
        JSContext *context = script->context;
        JSValue value = argv[0];
        if (JS_HasProperty(context, value, script->native_key)) {
            QuickJSInstance *mins = QuickJSInstance::GetInstance(ctx, value);
            if (mins) {
                delete mins;
            }
            JS_DeleteProperty(context, value, script->native_key, JS_PROP_THROW_STRICT);
        }
    }
    return JS_UNDEFINED;
}

JSValue QuickJSScript::callFunction(JSContext *ctx, JSValueConst this_val, int argc,
                                    JSValueConst *argv) {
    if (argc >= 2 && JS_IsString(argv[0]) && JS_IsArray(ctx, argv[1])) {
        const char *name = JS_ToCString(ctx, argv[0]);
        int count = JS_GetLength(ctx, argv[1]);

        const QuickJSScript *script = (const QuickJSScript *)JS_GetContextOpaque(ctx);
        QuickJSInstance *mins = QuickJSInstance::GetInstance(ctx, this_val);
        if (mins) {
            JSValue ret;
            if (count > 0) {
                variant_vector vs;
                vs.reserve(count);
                vs.resize(count);
                const Variant **ps = (const Variant **)malloc(count * sizeof(Variant *));
                for (int i = 0; i < count; ++i) {
                    vs[i] = script->toVariant(argv[i]);
                    ps[i] = &vs[i];
                }

                ret = script->toValue(mins->call(name, ps, count));
            } else {
                ret = script->toValue(mins->call(name, nullptr, 0));
            }
            return ret;
        }
    }
    return JS_UNDEFINED;
}

JSValue QuickJSScript::callStaticFunction(JSContext *ctx, JSValueConst this_val, int argc,
                                          JSValueConst *argv) {

    if (argc >= 2 && JS_IsString(argv[0]) && JS_IsArray(ctx, argv[1])) {
        const char *name = JS_ToCString(ctx, argv[0]);
        int count = JS_GetLength(ctx, argv[1]);

        const QuickJSScript *script = (const QuickJSScript *)JS_GetContextOpaque(ctx);
        JSValue data = JS_GetProperty(ctx, this_val, script->native_class_key);
        int64_t ptr = 0;
        if (JS_ToBigInt64(script->context, &ptr, data) == 0) {
            QuickJSClass *mcls = (QuickJSClass *)ptr;
            if (mcls) {
                JSValue ret;
                if (count > 0) {
                    variant_vector vs;
                    vs.reserve(count);
                    vs.resize(count);
                    const Variant **ps = (const Variant **)malloc(count * sizeof(Variant *));
                    for (int i = 0; i < count; ++i) {
                        vs[i] = script->toVariant(argv[i]);
                        ps[i] = &vs[i];
                    }

                    ret = script->toValue(mcls->call(name, ps, count));
                } else {
                    ret = script->toValue(mcls->call(name, nullptr, 0));
                }
                return ret;
            }
        }
    }
    return JS_UNDEFINED;
}

void QuickJSScript::defineFunction(const gc::StringName &name, const gc::Callback &function) {

}

gc::Variant QuickJSScript::toVariant(JSContext *context, JSValue value) {
    QuickJSScript *script = (QuickJSScript *)JS_GetContextOpaque(context);
    return script->toVariant(value);
}

gc::Variant QuickJSScript::toVariant(JSValue value) const {
    auto tag = JS_VALUE_GET_TAG(value);

    switch (tag) {
        case JS_TAG_INT: {
            int32_t v = 0;
            JS_ToInt32(context, &v, value);
            return v;
        }
        case JS_TAG_BIG_INT: {
            int64_t v = 0;
            JS_ToBigInt64(context, &v, value);
            return v;
        }
        case JS_TAG_BIG_FLOAT: {
            double v = 0;
            JS_ToFloat64(context, &v, value);
            return v;
        }
        case JS_TAG_FLOAT64: {
            double v = 0;
            JS_ToFloat64(context, &v, value);
            return v;
        }
        case JS_TAG_BOOL: {
            return (bool)JS_ToBool(context, value);
        }
        case JS_TAG_STRING: {
            const char *str = JS_ToCString(context, value);
            Variant ret(str);
            JS_FreeCString(context, str);
            return ret;
        }
        case JS_TAG_OBJECT: {
            QuickJSInstance *mins = QuickJSInstance::GetInstance(context, value);
            if (mins)
                return mins->getTarget();
            if (JS_IsArray(context, value)) {
                JSValue val = JS_GetPropertyStr(context, value, "length");
                int len = 0;
                JS_ToInt32(context, &len, val);
                JS_FreeValue(context, val);

                Array arr;
                for (int i = 0; i < len; ++i) {
                    JSValue val = JS_GetPropertyUint32(context, value, i);
                    arr.push_back(toVariant(val));
                    const_cast<QuickJSScript *>(this)->temp.push_back(val);
                }
                return arr;
            } else if (JS_IsFunction(context, value)) {
                Ref<QuickJSCallback> cb(new_t(QuickJSCallback, const_cast<QuickJSScript *>(this), value));
                return cb;
            } else {
                JSPropertyEnum *proEnum;
                uint32_t len;
                if (JS_GetOwnPropertyNames(context, &proEnum, &len, value, JS_GPN_STRING_MASK | JS_GPN_ENUM_ONLY) == 0) {
                    Map map;
                    for (int i = 0; i < len; ++i) {
                        JSPropertyEnum pro = proEnum[i];
                        const char *str = JS_AtomToCString(context, pro.atom);
                        JSValue val = JS_GetProperty(context, value, pro.atom);
                        map->set(str, toVariant(val));
                        const_cast<QuickJSScript *>(this)->temp.push_back(val);
                        JS_FreeCString(context, str);
                    }
                    js_free(context, proEnum);
                    return map;
                }
            }
            return Variant::null();
        }

        default:
        {
            if (JS_TAG_IS_FLOAT64(tag)) {
                double v = 0;
                JS_ToFloat64(context, &v, value);
                return v;
            }
        }
            break;
    }
    return Variant::null();
}

JSValue QuickJSScript::toValue(const gc::Variant &variant) const {
    switch (variant.getType()) {
        case Variant::TypeBool: {
            return JS_NewBool(context, (bool)variant);
        }
        case Variant::TypeChar:
        case Variant::TypeShort:
        case Variant::TypeInt:
        {
            return JS_NewInt32(context, variant);
        }

        case Variant::TypeLong:
        case Variant::TypeLongLong: {
            return JS_NewBigInt64(context, variant);
        }

        case Variant::TypeFloat:
        case Variant::TypeDouble: {
            return JS_NewFloat64(context, variant);
        }

        case Variant::TypeStringName: {
            StringName name = variant;
            return JS_NewString(context, name.str());
        }

        case Variant::TypeReference: {
            const Class *clz = variant.getTypeClass();
            if (clz->isTypeOf(_String::getClass())) {
                string name = variant;
                return JS_NewString(context, name.c_str());
            }
            Ref<Object> obj = variant;
            QuickJSInstance *mins = (QuickJSInstance *)obj->findScript(this);
            if (mins) {
                return mins->getScriptValue();
            } else {
                QuickJSClass *mcls = (QuickJSClass *)find(clz);
                if (mcls) {
                    JSValue obj = JS_CallConstructor(context, mcls->value, 0, nullptr);
                    if (JS_IsException(obj)) {
                        JSValue ex = JS_GetException(context);
                        PrintError(context, ex);
                        JS_FreeValue(context, ex);
                    } else {
                        QuickJSInstance *mins = (QuickJSInstance *)mcls->create(variant.get<Object>());
                        mins->setScriptValue(context, obj);
                        return obj;
                    }
                }
            }
        }
    }

    return JS_UNDEFINED;
}

JSValue QuickJSScript::newObject(JSContext *ctx, JSValueConst this_val, int argc,
                                 JSValueConst *argv) {
    if (argc >= 3 && JS_IsObject(argv[0]) && JS_IsString(argv[1]) && JS_IsArray(ctx, argv[2])) {
        QuickJSScript *script = (QuickJSScript *)JS_GetContextOpaque(ctx);
        const char *clsname = JS_ToCString(ctx, argv[1]);
        QuickJSClass *mcls = (QuickJSClass *)script->find(clsname);
        if (!mcls) {
            LOG(e, "Can not init object of type %s", clsname);
            JS_Throw(ctx, JS_NewError(ctx));
            return JS_EXCEPTION;
        }

        int count = JS_GetLength(ctx, argv[2]);
        QuickJSInstance *mins;
        if (count > 0) {
            Variant *vs = new Variant[count];
            const Variant **ps = (const gc::Variant **)malloc(count * sizeof(Variant *));
            for (int i = 0; i < count; ++i) {
                JSValue val = JS_GetPropertyUint32(ctx, argv[2], i);
                vs[i] = toVariant(ctx, val);
                ps[i] = &vs[i];
                script->temp.push_back(val);
            }
            mins = (QuickJSInstance *)mcls->newInstance(ps, count);
            delete [] vs;
            free(ps);
        } else {
            mins = (QuickJSInstance *)mcls->newInstance(nullptr, 0);
        }
        mins->setScriptValue(ctx, argv[0]);

        return JS_UNDEFINED;
    }
    return JS_EXCEPTION;
}

void QuickJSScript::insertCallback(gscript::QuickJSCallback *callback) {
    callbacks.insert(callback);
}

void QuickJSScript::removeCallback(gscript::QuickJSCallback *callback) {
    callbacks.erase(callback);
}

QuickJSClass::~QuickJSClass() {
    const QuickJSScript *script = (const QuickJSScript *)getScript();
    JS_DeleteProperty(script->context, value, script->native_class_key, 0);
    JS_FreeValue(script->context, value);
}

gc::ScriptInstance* QuickJSClass::makeInstance() const {
    return new QuickJSInstance;
}

JSValue QuickJSClass::callStatic(JSContext *ctx, JSValueConst this_val, int argc,
                                 JSValueConst *argv, int magic, JSValue *func_data) {
    int64_t ptr;
    if (JS_ToBigInt64(ctx, &ptr, func_data[0]) == 0) {
        const Method *method = (const Method *)ptr;
        const QuickJSScript *script = (const QuickJSScript *)JS_GetContextOpaque(ctx);
        JSValue ret;
        if (argc > 0) {
            vector<Variant> vs;
            const Variant **ps = (const Variant **)malloc(argc * sizeof(Variant *));
            vs.reserve(argc);
            vs.resize(argc);
            for (int i = 0; i < argc; ++i) {
                vs[i] = script->toVariant(argv[i]);
                ps[i] = &vs.at(i);
            }

            ret = script->toValue(method->call(nullptr, ps, argc));
            free(ps);
        } else {
            ret = script->toValue(method->call(nullptr, nullptr, 0));
        }

        return ret;
    }
    return JS_UNDEFINED;
}

JSValue QuickJSClass::callMember(JSContext *ctx, JSValueConst this_val, int argc,
                                 JSValueConst *argv, int magic, JSValue *func_data) {
    int64_t ptr;
    if (JS_ToBigInt64(ctx, &ptr, func_data[0]) == 0) {
        const Method *method = (const Method *)ptr;
        const QuickJSScript *script = (const QuickJSScript *)JS_GetContextOpaque(ctx);

        QuickJSInstance *mins = QuickJSInstance::GetInstance(ctx, this_val);
        if (mins) {
            JSValue ret;
            if (argc > 0) {
                vector<Variant> vs;
                const Variant **ps = (const Variant **)malloc(argc * sizeof(Variant *));
                vs.reserve(argc);
                vs.resize(argc);
                for (int i = 0; i < argc; ++i) {
                    vs[i] = script->toVariant(argv[i]);
                    ps[i] = &vs.at(i);
                }

                ret = script->toValue(method->call(mins->getTarget().get(), ps, argc));
                free(ps);
            } else {
                ret = script->toValue(method->call(mins->getTarget().get(), nullptr, 0));
            }

            return ret;
        }
    }
    return JS_UNDEFINED;
}

void QuickJSClass::bindScriptClass() {
    const QuickJSScript *script = (const QuickJSScript *)getScript();
    JSContext *context = script->context;
    const Class *cls = getNativeClass();

    value = JS_DupValue(context, JS_MKPTR(JS_TAG_OBJECT, getScriptClass()));

    JSValue prototype = JS_GetPropertyStr(context, value, "prototype");

    const pointer_map &methods = cls->getMethods();
    map<StringName, JSValue > func_cache;
    for (auto it = methods.begin(); it != methods.end(); ++it) {
        StringName name(it->first);
        const Method *method = (const Method *)it->second;

        switch (method->getType()) {
            case Method::Static: {
                JSValue methodValue = JS_NewBigInt64(context, (int64_t)method);
                JS_SetPropertyStr(
                        script->context,
                        value,
                        method->getName().str(),
                        JS_NewCFunctionData(
                                script->context,
                                callStatic,
                                method->getParamsCount(),
                                0,
                                1,
                                &methodValue
                                )
                        );
                JS_FreeValue(script->context, methodValue);
                break;
            }
            case Method::Member:
            case Method::ConstMb: {
                JSValue methodValue = JS_NewBigInt64(script->context, (int64_t)method);
                JSValue func = JS_NewCFunctionData(
                        script->context,
                        callMember,
                        method->getParamsCount(),
                        0,
                        1,
                        &methodValue
                );
                JS_SetPropertyStr(
                        script->context,
                        prototype,
                        method->getName().str(),
                        func);
                JS_FreeValue(script->context, methodValue);

                func_cache[method->getName()] = func;
                break;
            }
        }
    }

    const pointer_map &properties = cls->getProperties();
    for (auto it = properties.begin(), _e = properties.end(); it != _e; ++it) {
        StringName name(it->first);
        const Property *pro = (const Property *)it->second;
        JSValue getter = JS_UNDEFINED;
        JSValue setter = JS_UNDEFINED;
        if (pro->getGetter()) {
            const StringName &name = pro->getGetter()->getName();
            auto it = func_cache.find(name);
            if (it != func_cache.end()) {
                getter = JS_DupValue(context, it->second);
            }
        }
        if (pro->getSetter()) {
            const StringName &name = pro->getSetter()->getName();
            auto it = func_cache.find(name);
            if (it != func_cache.end()) {
                setter = JS_DupValue(context, it->second);
            }
        }

        JSAtom  atom = JS_NewAtom(context, name.str());
        JS_DefinePropertyGetSet(
                context,
                prototype,
                atom,
                getter,
                setter,
                0);
        JS_FreeAtom(context, atom);
    }

    JS_FreeValue(context, prototype);
}

gc::Variant QuickJSClass::apply(const gc::StringName &name, const gc::Variant **params, int count) const {
    QuickJSScript *script = (QuickJSScript *)getScript();
    JSContext *context = script->context;
    JSAtom  atom = JS_NewAtom(context, name.str());
    Variant ret;
    if (count > 0) {
        vector<JSValue> argv;
        argv.reserve(count);
        argv.resize(count);
        for (int i = 0; i < count; ++i) {
            argv[i] = script->toValue(*params[i]);
        }
        JSValue val = JS_Invoke(context, value, atom, count, argv.data());
        ret = script->toVariant(val);
        for (auto it = argv.begin(); it != argv.end(); ++it) {
            JS_FreeValue(context, *it);
        }
        script->temp.push_back(val);
    } else {
        JSValue val = JS_Invoke(context, value, atom, 0, nullptr);
        ret = script->toVariant(val);
        script->temp.push_back(val);
    }
    return ret;
}

void QuickJSInstance::finalizer(JSRuntime *rt, JSValue val) {
    QuickJSScript *script = (QuickJSScript *)JS_GetRuntimeOpaque(rt);
    QuickJSInstance *mins = (QuickJSInstance *)JS_GetOpaque(val, script->data_class_id);
    if (mins) {
        delete mins;
    }
}

gc::Variant QuickJSInstance::apply(const gc::StringName &name, const gc::Variant **params, int count) {
    QuickJSScript *script = (QuickJSScript *)this->getScript();

    JSValue value = JS_MKPTR(JS_TAG_OBJECT, object);
    JSAtom  atom = JS_NewAtom(script->context, name.str());

    JSValue *argv = nullptr;
    if (count > 0) {
        argv = (JSValue *)malloc(count * sizeof(JSValue));
        for (int i = 0; i < count; ++i) {
            argv[i] = script->toValue(*params[i]);
        }
    }

    JSValue result = JS_Invoke(script->context, value, atom, count, argv);
    Variant ret = script->toVariant(result);
    script->temp.push_back(result);

    JS_FreeAtom(script->context, atom);
    if (argv) {
        for (int i = 0; i < count; ++i) {
            JS_FreeValue(script->context, argv[i]);
        }
        free(argv);
    }

    return ret;
}

void QuickJSInstance::setScriptValue(JSContext *ctx, JSValue value) {
    QuickJSScript *script = (QuickJSScript *)JS_GetContextOpaque(ctx);
    if (script->data_class_id == 0) {
        JS_NewClassID(&script->data_class_id);
        JSClassDef def = {
                .class_name = "Data",
                .finalizer = QuickJSInstance::finalizer
        };
        JS_NewClass(JS_GetRuntime(ctx), script->data_class_id, &def);
    }

    data = JS_NewObjectClass(ctx, script->data_class_id);
    JS_SetOpaque(data, this);
    JS_SetProperty(ctx, value, script->native_key, data);

    object = JS_VALUE_GET_OBJ(value);
}

JSValue QuickJSInstance::getScriptValue() {
    QuickJSScript *script = (QuickJSScript *)getScript();
    return JS_DupValue(script->context, JS_MKPTR(JS_TAG_OBJECT, object));
}

QuickJSInstance::~QuickJSInstance() {
    QuickJSScript *script = (QuickJSScript *)getScript();
    JS_SetOpaque(data, nullptr);
}

void QuickJSCallback::initialize(gscript::QuickJSScript *script, JSValue value) {
    this->script = script;
    this->value = JS_DupValue(script->context, value);
    script->insertCallback(this);
}

QuickJSCallback::~QuickJSCallback() {
    if (script) {
        script->removeCallback(this);
        JS_FreeValue(script->context, value);
    }
}

void QuickJSCallback::clear() {
    if (script) {
        JS_FreeValue(script->context, value);
        script = nullptr;
    }
}

gc::Variant QuickJSCallback::invoke(const gc::Array &params) {
    if (script) {
        JSContext *context = script->context;
        size_t len = params.size();
        vector<JSValue> argv;
        argv.reserve(len);
        argv.resize(len);
        for (int i = 0; i < len; ++i) {
            argv[i] = script->toValue(params.at(i));
        }
        JSValue val = JS_Call(context, value, JS_NULL, len, argv.data());
        Variant ret;
        if (JS_IsException(val)) {
            JSValue ex = JS_GetException(context);
            PrintError(context, ex, "[Eval]");
            JS_FreeValue(context, ex);
        } else {
            ret = script->toVariant(val);
        }
        for (int i = 0; i < len; ++i) {
            JS_FreeValue(context, argv[i]);
        }
        script->temp.push_back(val);
        return ret;
    }
    return Variant::null();
}

QuickJSInstance * QuickJSInstance::GetInstance(JSContext *context, JSValue value) {
    QuickJSScript *script = (QuickJSScript *)JS_GetContextOpaque(context);
    JSValue data = JS_GetProperty(context, value, script->native_key);
    QuickJSInstance *mins = (QuickJSInstance *)JS_GetOpaque(data, script->data_class_id);
    JS_FreeValue(context, data);
    return mins;
}