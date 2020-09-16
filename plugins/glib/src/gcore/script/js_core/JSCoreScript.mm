
#include "JSCoreScript.h"
#include <core/Array.h>
#include <core/Map.h>
#include <core/String.h>
#import <JavaScriptCore/JavaScriptCore.h>
#include <sstream>

using namespace gc;
using namespace gscript;
using namespace std;

const int JSCoreInfo = 0;
const int JSCoreWarn = 1;
const int JSCoreError = 2;

#define CHS_SIZE 256

@interface JSCoreContext : NSObject {
}

@property (nonatomic, strong) JSContext *context;
@property (nonatomic) JSCoreScript *script;
@property (nonatomic, strong) NSMutableDictionary<NSString *, JSValue *> *modules;
@property (nonatomic, strong) JSValue *convert;
@property (nonatomic, strong) JSValue *privateKey;
@property (nonatomic, strong) JSValue *creator;
@property (nonatomic, strong) JSValue *getset;

- (id)initWithScript:(JSCoreScript *)script;

- (void)setupWithDir:(NSString *)dir;

- (JSValue *)loadModuile:(NSString *)path;

@end

namespace gscript {

    struct JSValuePair {
        JSValueRef value;
        Variant variant;
    };

    struct ContextInfo {
        JSValueRef privateKey;
        map<void*, JSClassRef> managedDataClasses;
    };
    map<JSContextRef, ContextInfo> contexts;

    JSClassRef getDataClass(ContextInfo &ctx, void (*destroy)(JSObjectRef object)) {
        auto it = ctx.managedDataClasses.find((void*)destroy);
        if (it == ctx.managedDataClasses.end()) {
            JSClassDefinition def = kJSClassDefinitionEmpty;
            // def.initialize = onInit;
            def.finalize = destroy;
            JSClassRef cls = JSClassCreate(&def);
            ctx.managedDataClasses[(void*)destroy] = cls;
            return cls;
        }
        return it->second;
    }

    bool setPrivateData2(JSContextRef ctx, JSObjectRef object, void *data, void (*destroy)(JSObjectRef object) = nullptr) {
        auto it = contexts.find(ctx);
        if (it != contexts.end()) {
            JSObjectRef tar = JSObjectMake(ctx, getDataClass(it->second, destroy), data);
            if (tar) {
                JSValueRef ex;
                JSObjectSetPropertyForKey(ctx, object,
                                          it->second.privateKey,
                                          tar,
                                          kJSPropertyAttributeNone,
                                          &ex);
                return true;
            }
        }
        return false;
    }

    void removePrivateData(JSContextRef ctx, JSObjectRef object) {
        auto it = contexts.find(ctx);
        if (it != contexts.end()) {
            JSValueRef ex;
            JSObjectDeletePropertyForKey(ctx, object, it->second.privateKey, &ex);
        }
    }

    void *getPrivateData(JSContextRef ctx, JSObjectRef object) {
        auto it = contexts.find(ctx);
        if (it != contexts.end()) {
            JSValueRef ex;
            JSValueRef res = JSObjectGetPropertyForKey(ctx, object, it->second.privateKey, &ex);
            if (JSValueIsObject(ctx, res)) {
                return JSObjectGetPrivate((JSObjectRef) res);
            }
        }
        return nullptr;
    }

    void onInit(JSContextRef ctx, JSObjectRef object) {
        NSLog(@"onInit");
    }

    void onDestroyInstance(JSObjectRef object) {
        NSLog(@"onDestroyInstance");
        JSCoreInstance *mins = (JSCoreInstance *)JSObjectGetPrivate(object);
        if (mins) {
            delete mins;
        }
    }

    void onDestroyClass(JSObjectRef object) {
        NSLog(@"onDestroyClass");
        JSCoreClass *mcls = (JSCoreClass *)JSObjectGetPrivate(object);
        if (mcls) {
            delete mcls;
        }
    }

    JSCoreContext *ctx(JSCoreScript *script) {
        return (__bridge JSCoreContext *)script->getContext();
    }

    const Variant & findCache(JSContextRef ctx, const std::list<JSValuePair> &cache, JSValueRef value) {
        for (auto it = cache.begin(), _e = cache.end(); it != _e; ++it) {
            JSValueRef ex = nullptr;
            if (JSValueIsEqual(ctx, it->value, value, &ex)) {
                return it->variant;
            }
        }
        return Variant::null();
    }

    Variant toVariant(JSContextRef ctx, JSValueRef value);
    Variant _toVariant(JSContextRef ctx, JSValueRef value, std::list<JSValuePair> &cache) {
        Variant ret;
        JSValueRef exception = nullptr;
        if (JSValueIsNumber(ctx, value)) {
            ret = JSValueToNumber(ctx, value, &exception);
        } else if (JSValueIsString(ctx, value) || JSValueIsSymbol(ctx, value)) {
            JSStringRef jstr = JSValueToStringCopy(ctx, value, &exception);
            size_t str_size = JSStringGetMaximumUTF8CStringSize(jstr);
            char *cstr = (char *)malloc(str_size);
            JSStringGetUTF8CString(jstr, cstr, str_size);
            ret = cstr;
            free(cstr);
            JSStringRelease(jstr);
        } else if (JSValueIsBoolean(ctx, value)) {
            ret = JSValueToBoolean(ctx, value);
        } else if (JSValueIsArray(ctx, value)) {
            ret = findCache(ctx, cache, value);
            if (!ret) {
                JSStringRef name = JSStringCreateWithUTF8CString("length");
                JSValueRef length = JSObjectGetPropertyForKey(ctx, (JSObjectRef)value, JSValueMakeString(ctx, name), &exception);
                JSStringRelease(name);
                
                if (exception == nullptr) {
                    Array arr;
                    int len = JSValueToNumber(ctx, length, &exception);
                    for (int i = 0; i < len; ++i) {
                        arr.push_back(_toVariant(ctx, JSObjectGetPropertyAtIndex(ctx, (JSObjectRef)value, i, &exception), cache));
                        if (exception) {
                            break;
                        }
                    }
                    ret = arr;
                    cache.push_back({
                        .value = value,
                        .variant = ret
                    });
                }
            }
            
        } else if (JSValueIsObject(ctx, value)) {
            JSObjectRef obj = (JSObjectRef)value;
            if (JSObjectIsFunction(ctx, obj)) {
                JSObjectRef globalObj = JSContextGetGlobalObject(ctx);
                JSCoreScript *script = (JSCoreScript *)getPrivateData(ctx, globalObj);
                JSCoreContext *context = gscript::ctx(script);
                JSValue *func = [JSValue valueWithJSValueRef:obj inContext:context.context];
                JSValue *cb = [context.convert callWithArguments:@[func]];
                ret = toVariant(ctx, cb.JSValueRef);
            } else {
                JSCoreInstance *ins = (JSCoreInstance *)getPrivateData(ctx, obj);
                if (ins) {
                    return ins->getTarget();
                } else {
                    ret = findCache(ctx, cache, value);
                    if (!ret) {
                        Map map;
                        JSPropertyNameArrayRef names = JSObjectCopyPropertyNames(ctx, obj);
                        size_t count = JSPropertyNameArrayGetCount(names);
                        for (int i = 0; i < count; ++i) {
                            JSStringRef name = JSPropertyNameArrayGetNameAtIndex(names, i);
                            size_t name_len = JSStringGetMaximumUTF8CStringSize(name);
                            string str;
                            str.resize(name_len);
                            JSStringGetUTF8CString(name, (char *)str.data(), str.size());
                            map.set(str, _toVariant(ctx, JSObjectGetPropertyForKey(ctx, obj, JSValueMakeString(ctx, name), &exception), cache));
                            if (exception) {
                                break;
                            }
                        }
                        JSPropertyNameArrayRelease(names);

                        if (exception == nullptr) {
                            ret = map;
                            cache.push_back({
                                .value = value,
                                .variant = ret
                            });
                        }
                    }
                }
            }
        }
        if (exception) {
            NSLog(@"%@", exception);
        }
        return ret;
    }

    Variant toVariant(JSContextRef ctx, JSValueRef value) {
        std::list<JSValuePair> cache;
        return _toVariant(ctx, value, cache);
    }

    JSValueRef toValue(JSContextRef _ctx, const Variant &var) {
        switch (var.getType()) {
            case Variant::TypeChar:
            case Variant::TypeShort:
            case Variant::TypeInt:
            case Variant::TypeLong:
            case Variant::TypeLongLong:
            case Variant::TypeFloat:
            case Variant::TypeDouble:
                return JSValueMakeNumber(_ctx, var);
                
            case Variant::TypeBool:
                return JSValueMakeBoolean(_ctx, var);
            case Variant::TypeStringName: {
                StringName name = var;
                JSStringRef strref = JSStringCreateWithUTF8CString(name.str());
                JSValueRef ret = JSValueMakeString(_ctx, strref);
                JSStringRelease(strref);
                return ret;
            }
            case Variant::TypeReference: {
                const gc::Class* cls = var.getTypeClass();
                if (cls->isTypeOf(gc::_String::getClass())) {
                    JSStringRef strref = JSStringCreateWithUTF8CString(var);
                    JSValueRef ret = JSValueMakeString(_ctx, strref);
                    JSStringRelease(strref);
                    return ret;
//                } else if (cls->isTypeOf(gc::_Array::getClass())) {
//                    Array arr = var;
//                    size_t len = arr->size();
//                    JSValueRef *arguments = (JSValueRef *)malloc(sizeof(const JSValueRef) * len);
//                    for (int i = 0; i < len; ++i) {
//                        arguments[i] = toValue(ctx, arr.at(i));
//                    }
//                    JSValueRef ex = nullptr;
//                    JSValueRef ret = JSObjectMakeArray(ctx, len, arguments, &ex);
//                    free(arguments);
//                    if (ex) {
//                        JSStringRef str = JSValueToStringCopy(ctx, ex, nullptr);
//                        char chs[256];
//                        JSStringGetUTF8CString(str, chs, 256);
//                        LOG(e, "%s", chs);
//                        JSStringRelease(str);
//                    }
//                    return ret;
//                } else if (cls->isTypeOf(gc::_Map::getClass())) {
//                    Map map = var;
//                    JSObjectRef obj = JSObjectMake(ctx, nullptr, nullptr);
//                    for (auto it = map->begin(), _e = map->end(); it != _e; ++it) {
//                        JSStringRef key = JSStringCreateWithUTF8CString(it->first.c_str());
//                        JSValueRef ex = nullptr;
//                        JSObjectSetPropertyForKey(ctx, obj,
//                                                  JSValueMakeString(ctx, key),
//                                                  toValue(ctx, it->second),
//                                                  kJSPropertyAttributeNone,
//                                                  &ex);
//                        JSStringRelease(key);
//
//                        if (ex) {
//                            JSStringRef str = JSValueToStringCopy(ctx, ex, nullptr);
//                            char chs[256];
//                            JSStringGetUTF8CString(str, chs, 256);
//                            LOG(e, "%s", chs);
//                            JSStringRelease(str);
//                        }
//                    }
//
//                    return obj;
                } else {
                    Ref<Object> obj = var;
                    JSCoreScript *script = (JSCoreScript *)getPrivateData(_ctx, JSContextGetGlobalObject(_ctx));
                    JSCoreInstance *mins = (JSCoreInstance *)obj->findScript(script->getName());
                    if (mins) {
                        return (JSValueRef)mins->getValue();
                    } else {
                        JSCoreClass *mcls = (JSCoreClass *)script->find(cls);
                        if (mcls) {
                            JSValueRef Class = (JSValueRef)mcls->getScriptClass();
                            JSCoreContext *context = ctx(script);
                            JSValue *nObj = [context.creator callWithArguments:@[[JSValue valueWithJSValueRef:Class inContext:context.context]]];
                            if (nObj.isObject) {
                                JSCoreInstance *mins = (JSCoreInstance *)mcls->create(var.get<Object>());
                                mins->setValue((void *)nObj.JSValueRef);
                                setPrivateData2(_ctx, (JSObjectRef)nObj.JSValueRef, mins, onDestroyInstance);
                                return nObj.JSValueRef;
                            }
                            
                        }
                    }
                }
            }
                
            default: break;
        }
        return JSValueMakeUndefined(_ctx);
    }

    void printFunction(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception, stringstream &ss) {
        for (int i = 0; i < argumentCount; ++i) {
            JSStringRef jstr = JSValueToStringCopy(ctx, arguments[i], exception);
            if (!exception) {
                char chs[CHS_SIZE];
                if (i != 0) ss << "\n";
                ss << JSStringGetUTF8CString(jstr, chs, CHS_SIZE);
            }
        }
    }

    JSValueRef _printInfo(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
        stringstream ss;
        ss << "[I] ";
        printFunction(ctx, function, thisObject, argumentCount, arguments, exception, ss);
        std::string str = ss.str();
        NSLog(@"%s", str.c_str());
    }

    JSValueRef _printWarn(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
        stringstream ss;
        ss << "[W] ";
        printFunction(ctx, function, thisObject, argumentCount, arguments, exception, ss);
        std::string str = ss.str();
        NSLog(@"%s", str.c_str());
    }

    JSValueRef _printError(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
        stringstream ss;
        ss << "[E] ";
        printFunction(ctx, function, thisObject, argumentCount, arguments, exception, ss);
        std::string str = ss.str();
        NSLog(@"%s", str.c_str());
    }

    JSValueRef _callStaticFunction(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
        JSCoreClass *cls = (JSCoreClass *)getPrivateData(ctx, thisObject);
        const Method *method = (const Method *)getPrivateData(ctx, function);
        
        Variant ret;
        if (argumentCount > 0) {
            vector<Variant> vs;
            vs.resize(argumentCount);
            vector<Variant *> args;
            args.resize(argumentCount);
            for (int i = 0; i < argumentCount; ++i) {
                vs[i] = toVariant(ctx, arguments[i]);
                args[i] = &vs[i];
            }
            ret = method->call(nullptr, (const Variant **)args.data(), (int)args.size());
        } else {
            ret = method->call(nullptr, nullptr, 0);
        }
        
        return toValue(ctx, ret);
    }

    JSValueRef _callMenberFunction(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
        JSCoreInstance *mins = (JSCoreInstance *)getPrivateData(ctx, thisObject);
        const Method *method = (const Method *)getPrivateData(ctx, function);
        
        Variant ret;
        if (argumentCount > 0) {
            vector<Variant> vs;
            vs.resize(argumentCount);
            vector<Variant *> args;
            args.resize(argumentCount);
            for (int i = 0; i < argumentCount; ++i) {
                vs[i] = toVariant(ctx, arguments[i]);
                args[i] = &vs[i];
            }
            ret = method->call(mins->getTarget().get(), (const Variant **)args.data(), (int)args.size());
        } else {
            ret = method->call(mins->getTarget().get(), nullptr, 0);
        }
        return toValue(ctx, ret);
    }
}

@implementation JSCoreContext

- (id)initWithScript:(JSCoreScript *)script {
    self = [super init];
    if (self) {
        _script = script;
        self.modules = [NSMutableDictionary dictionary];
        
        __weak JSCoreContext *that = self;
        _context = [[JSContext alloc] init];
        _privateKey = [JSValue valueWithNewObjectInContext:_context];
        JSContextRef ctx = _context.JSGlobalContextRef;
        
        self.creator = [_context evaluateScript:@"(function(Cls) {return new Cls();})"];
        self.getset = [_context evaluateScript:@"(function(propertype, name, getter, setter) { Object.defineProperty(propertype, name, {get: getter ? getter : undefined, set: setter ? setter : undefined, configurable: true}) })"];
        
        contexts[ctx] = ContextInfo{
            .privateKey = _privateKey.JSValueRef,
        };
        setPrivateData2(ctx, (JSObjectRef)_context.globalObject.JSValueRef, script);
        
        [_context setExceptionHandler:^(JSContext *context, JSValue *exception) {
            NSLog(@"JavaScriptContext: \n%@", exception);
        }];
        
        JSObjectRef func = JSObjectMakeFunctionWithCallback(_context.JSGlobalContextRef,
                                                            JSStringCreateWithUTF8CString("_printInfo"),
                                                            _printInfo);
        [_context.globalObject setObject:[JSValue valueWithJSValueRef:func inContext:_context]
                       forKeyedSubscript:@"_printInfo"];
        
        func = JSObjectMakeFunctionWithCallback(_context.JSGlobalContextRef,
                                                JSStringCreateWithUTF8CString("_printWarn"),
                                                _printWarn);
        [_context.globalObject setObject:[JSValue valueWithJSValueRef:func inContext:_context]
                       forKeyedSubscript:@"_printWarn"];
        
        func = JSObjectMakeFunctionWithCallback(_context.JSGlobalContextRef,
                                                JSStringCreateWithUTF8CString("_printError"),
                                                _printError);
        [_context.globalObject setObject:[JSValue valueWithJSValueRef:func inContext:_context]
                       forKeyedSubscript:@"_printError"];
        
        [_context.globalObject setObject:^(JSValue *Class, NSString *className) {
            JSCoreScript *script = that.script;
            if (script) {
                script->regClass((void *)Class.JSValueRef, className.UTF8String);
            }
        } forKeyedSubscript:@"_registerClass"];
        [_context.globalObject setObject:^(JSValue *target, NSString *className, JSValue *arr) {
            [that newObject:target withClassName:className withArguments:arr];
        } forKeyedSubscript:@"_newObject"];
        [_context.globalObject setObject:^(JSValue *target) {
            [that destroyObject:target];
        } forKeyedSubscript:@"_destroyObject"];
        [_context.globalObject setObject:^JSValue *(NSString *name, JSValue *args) {
            if (name && args.isArray) {
                return [that call:JSContext.currentThis witName:name withArgs:args];
            }
            return nil;
        } forKeyedSubscript:@"_call"];
        [_context.globalObject setObject:^JSValue *(NSString *name, JSValue *args) {
            if (name && args.isArray) {
                return [that callStatic:JSContext.currentThis withName:name withArgs:args];
            }
            return nil;
        } forKeyedSubscript:@"_callStatic"];
        [_context evaluateScript:@"this.global = this;"];
    }
    return self;
}

- (void)dealloc {
    auto it = contexts.find(_context.JSGlobalContextRef);
    if (it != contexts.end()) {
        map<void*, JSClassRef> &amap = it->second.managedDataClasses;
        for (auto it = amap.begin(), _e = amap.end(); it != _e; ++it) {
            JSClassRelease(it->second);
        }
        contexts.erase(it);
    }
}

- (void)newObject:(JSValue *)target withClassName:(NSString *)className withArguments:(JSValue *)args {
    JSContext *ctx = [JSContext currentContext];
    JSCoreClass *mcls = (JSCoreClass *)self.script->find(StringName(className.UTF8String));
    if (!mcls) {
        LOG(e, "Can not init object of type %s", className.UTF8String);
        [self.context setException:[JSValue valueWithNewErrorFromMessage:@"Init object failed!"
                                                               inContext:ctx]];
        return;
    }
    
    Array arr = toVariant(ctx.JSGlobalContextRef, args.JSValueRef);
    size_t size = arr->size();
    JSCoreInstance *mins = nullptr;
    if (size > 0) {
        Variant ** vars = (Variant **)malloc(sizeof(Variant *) * size);
        for (size_t i = 0, t = size; i < t; ++i) {
            vars[i] = &arr->at(i);
        }
        mins = (JSCoreInstance *)mcls->newInstance((const Variant **)vars, (int)size);
    } else {
        mins = (JSCoreInstance *)mcls->newInstance(nullptr, 0);
    }
    
    mins->setValue((void*)target.JSValueRef);
//    bool res = JSObjectSetPrivate((JSObjectRef)target.JSValueRef, mins);
//    NSLog(@"new Object %@", res ? @"YES": @"NO");
    setPrivateData2(ctx.JSGlobalContextRef, (JSObjectRef)target.JSValueRef, mins, onDestroyInstance);
}

- (void)destroyObject:(JSValue *)target {
    JSContext *ctx = [JSContext currentContext];
    JSCoreInstance *mins = (JSCoreInstance *)getPrivateData(ctx.JSGlobalContextRef, (JSObjectRef)target.JSValueRef);
    if (mins) {
        delete mins;
        removePrivateData(_context.JSGlobalContextRef, (JSObjectRef)target.JSValueRef);
    }
}

- (JSValue *)call:(JSValue *)thisObject witName:(NSString *)name withArgs:(JSValue *)args {
    if (thisObject.isObject) {
        JSContext *ctx = [JSContext currentContext];
        JSObjectRef obj = (JSObjectRef)thisObject.JSValueRef;
        JSCoreInstance *mins = (JSCoreInstance *)getPrivateData(ctx.JSGlobalContextRef, obj);
        
        if (mins) {
            Reference target = mins->getTarget();
            const Method *method = target->getInstanceClass()->getMethod(name.UTF8String);
            if (method && (method->getType() == gc::Method::Member || method->getType() == gc::Method::ConstMb)) {
                JSContextRef ctx = JSContext.currentContext.JSGlobalContextRef;
                Array arr = toVariant(ctx, args.JSValueRef);
                size_t len = arr->size();
                vector<Variant *> args;
                args.resize(len);
                for (size_t i = 0; i < len; ++i) {
                    args[i] = &arr->at(i);
                }
                
                JSValueRef value = toValue(ctx, method->call(target.get(), (const Variant **)args.data(), (int)len));
                return [JSValue valueWithJSValueRef:value inContext:JSContext.currentContext];
            }
        }
        
    }
    return nil;
}

- (JSValue *)callStatic:(JSValue *)thisObject withName:(NSString *)name withArgs:(JSValue *)args {
    if (thisObject.isObject) {
        JSContext *ctx = [JSContext currentContext];
        JSObjectRef obj = (JSObjectRef)thisObject.JSValueRef;
        JSCoreClass *mcls = (JSCoreClass *)getPrivateData(ctx.JSGlobalContextRef, obj);
        
        if (mcls) {
            const Method *method = mcls->getNativeClass()->getMethod(name.UTF8String);
            if (method && method->getType() == gc::Method::Static) {
                JSContextRef ctx = JSContext.currentContext.JSGlobalContextRef;
                Array arr = toVariant(ctx, args.JSValueRef);
                size_t len = arr->size();
                vector<Variant *> args;
                args.resize(len);
                for (size_t i = 0; i < len; ++i) {
                    args[i] = &arr->at(i);
                }
                
                JSValueRef value = toValue(ctx, method->call(nullptr, (const Variant **)args.data(), (int)len));
                return [JSValue valueWithJSValueRef:value inContext:JSContext.currentContext];
            }
        }
    }
    return nil;
}

#define B_SIZW 4096

+ (NSString *)caculatePath:(NSString *)base withPath:(NSString *)path {
    NSMutableArray *segs = [NSMutableArray arrayWithArray:[base componentsSeparatedByString:@"/"]];
    [segs removeLastObject];
    NSArray *psegs = [path componentsSeparatedByString:@"/"];
    for (NSString *seg in psegs) {
        if (seg.length == 0|| [seg isEqualToString:@"."]) {
            
        } else if ([seg isEqualToString:@".."]) {
            [segs removeLastObject];
        } else {
            [segs addObject:seg];
        }
    }
    NSString *segPath = [segs componentsJoinedByString:@"/"];
    if ([segPath characterAtIndex:0] != '/') {
        segPath = [NSString stringWithFormat:@"/%@", segPath];
    }
    return segPath;
}

- (JSValue *)loadModuile:(NSString *)path {
    JSValue *value = [self.modules objectForKey:path];
    if (!value) {
        JSValue *module = [JSValue valueWithNewObjectInContext:self.context];
        
        [self.modules setObject:module forKey:path];

        __weak JSCoreContext *that = self;
        NSData *raw = [NSData dataWithContentsOfFile:path];
        NSString *data = [[NSString alloc] initWithData:raw
                                               encoding:NSUTF8StringEncoding];
        if (data) {
            if ([path.pathExtension.lowercaseString isEqualToString:@"js"]) {
                JSValue *exports = [JSValue valueWithNewObjectInContext:self.context];
                [module setObject:exports forKeyedSubscript:@"exports"];
                NSString *script = [@[
                    @"(function(exports, require, module, __filename, __dirname) {",
                    data,
                    @"})"
                ] componentsJoinedByString:@"\n"];
                JSValue *value = [self.context evaluateScript:script
                                                withSourceURL:[NSURL fileURLWithPath:path]];
                JSValue *require = [JSValue valueWithObject:^JSValue *(NSString *src) {
                    if (src) {
                        NSString *tpath = [JSCoreContext caculatePath:path withPath:src];
                        NSFileManager *fm = [NSFileManager defaultManager];
                        NSString *tempPath;
                        if ([fm fileExistsAtPath:(tempPath = [tpath stringByAppendingPathExtension:@"js"])]) {
                            return [that loadModuile:tempPath];
                        } else if ([fm fileExistsAtPath:(tempPath = [tpath stringByAppendingPathExtension:@"json"])]) {
                            return [that loadModuile:tempPath];
                        }
                    }
                    return [JSValue valueWithNewObjectInContext:that.context];
                } inContext:self.context];
                [value callWithArguments:@[exports, require, module, path, path.stringByDeletingLastPathComponent]];
            } else if ([path.pathExtension.lowercaseString isEqualToString:@"json"]) {
                NSError *error;
                id obj = [NSJSONSerialization JSONObjectWithData:raw
                                                         options:NSJSONReadingAllowFragments
                                                           error:&error];
                if (obj) {
                    [module setObject:obj forKeyedSubscript:@"exports"];
                }
            }
        }
        
        value = module;
    }
    return [value objectForKeyedSubscript:@"exports"];
}

- (void)setupWithDir:(NSString *)dir {
    [self loadModuile:[dir stringByAppendingPathComponent:@"env.js"]];
    self.convert = [self loadModuile:[dir stringByAppendingPathComponent:@"convert.js"]];
}

@end

#define CTX ((__bridge JSCoreContext *)context)

JSCoreScript::JSCoreScript(const char *dir) : gc::Script("jscore") {
    JSCoreContext *ctx = [[JSCoreContext alloc] initWithScript:this];
    context = (void *)CFBridgingRetain(ctx);
    
    [CTX setupWithDir:[NSString stringWithUTF8String:dir]];
}

Variant JSCoreScript::runScript(const char *script, const char *filename) const {
    NSURL *url = nil;
    if (filename) {
        url = [NSURL fileURLWithPath:[NSString stringWithUTF8String:filename]];
    }
    if (script) {
        JSValue *value = [CTX.context evaluateScript:[NSString stringWithUTF8String:script]
                                       withSourceURL:url];
        return toVariant(CTX.context.JSGlobalContextRef, value.JSValueRef);
    }
    return Variant::null();
}

Variant JSCoreScript::runFile(const char *filepath) const {
    if (filepath) {
        JSValue *value = [CTX loadModuile:[NSString stringWithUTF8String:filepath]];
        return toVariant(CTX.context.JSGlobalContextRef, value.JSValueRef);
    }
    return Variant::null();
}

JSCoreScript::~JSCoreScript() {
    CFBridgingRelease(context);
}

gc::ScriptClass *JSCoreScript::makeClass() const {
    return new JSCoreClass;
}

ScriptInstance *JSCoreScript::newBuff(const std::string &cls_name, gc::Object *target, const gc::Variant **params, int count) const {
    
}

JSCoreClass::~JSCoreClass() {
    CFBridgingRelease(getScriptClass());
}

gc::Variant JSCoreClass::apply(const gc::StringName &name, const gc::Variant **params, int count) const {
    JSValueRef Class = (JSValueRef)getScriptClass();
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:count];
    JSCoreScript *script = (JSCoreScript *)getScript();
    JSCoreContext *context = ctx(script);
    for (int i = 0; i < count; ++i) {
        JSValueRef value = toValue(context.context.JSGlobalContextRef, *params[i]);
        [arr addObject:[JSValue valueWithJSValueRef:value inContext:context.context]];
    }
    JSValue *_Cls = [JSValue valueWithJSValueRef:Class
                                       inContext:context.context];
    JSValue *res = [_Cls invokeMethod:[NSString stringWithUTF8String:name.str()]
                         withArguments:arr];
    return toVariant(context.context.JSGlobalContextRef, res.JSValueRef);
}

ScriptInstance *JSCoreClass::makeInstance() const {
    return new JSCoreInstance;
}

void JSCoreClass::bindScriptClass() {
    JSCoreScript *script = (JSCoreScript *)getScript();
    JSObjectRef Class = (JSObjectRef)getScriptClass();
    const gc::Class *cls = getNativeClass();

    JSValueRef ex;
    JSCoreContext *context = ctx(script);
    JSContextRef _ctx = context.context.JSGlobalContextRef;
    setPrivateData2(_ctx, Class, this, onDestroyClass);
    JSStringRef propertyKey = JSStringCreateWithUTF8CString("prototype");
    JSValueRef prototypeRef = JSObjectGetProperty(_ctx, Class, propertyKey, &ex);
    JSStringRelease(propertyKey);
    JSValue *prototype = [JSValue valueWithJSValueRef:prototypeRef
                                            inContext:context.context];
    JSValue *_Class = [JSValue valueWithJSValueRef:Class
                                         inContext:context.context];
    
    pointer_map func_cache;
    const pointer_map &methods = cls->getMethods();
    for (auto it = methods.begin(); it != methods.end(); ++it) {
        StringName name(it->first);
        const Method *method = (const Method *)it->second;
        
        switch (method->getType()) {
            case Method::Static: {
                JSObjectRef func = JSObjectMakeFunctionWithCallback(context.context.JSGlobalContextRef,
                                                                    JSStringCreateWithUTF8CString(name.str()),
                                                                    _callStaticFunction);
                setPrivateData2(_ctx, func, (void *)method);
                [_Class setObject:[JSValue valueWithJSValueRef:func inContext:context.context]
               forKeyedSubscript:[NSString stringWithUTF8String:name.str()]];
                break;
            }
            case Method::Member:
            case Method::ConstMb: {
                JSObjectRef func = JSObjectMakeFunctionWithCallback(context.context.JSGlobalContextRef,
                                                                    JSStringCreateWithUTF8CString(name.str()),
                                                                    _callMenberFunction);
                setPrivateData2(_ctx, func, (void *)method);
                [prototype setObject:[JSValue valueWithJSValueRef:func inContext:context.context]
                   forKeyedSubscript:[NSString stringWithUTF8String:name.str()]];
                func_cache[name] = func;
                break;
            }
            default: break;
        }
    }
    
    auto& properties = cls->getProperties();
    for (auto it = properties.begin(), _e = properties.end(); it != _e; ++it) {
        StringName name(it->first);
        const Property *property = (const Property *)it->second;
        JSObjectRef getter = nullptr, setter = nullptr;
        if (property->getGetter()) {
            auto it = func_cache.find(property->getGetter()->getName());
            if (it != func_cache.end()) {
                getter = (JSObjectRef)it->second;
            }
        }
        if (property->getSetter()) {
            auto it = func_cache.find(property->getSetter()->getName());
            if (it != func_cache.end()) {
                setter = (JSObjectRef)it->second;
            }
        }
        
        [context.getset callWithArguments:@[
            prototype,
            [NSString stringWithUTF8String:name.str()],
            getter ? [JSValue valueWithJSValueRef:getter inContext:context.context] : [NSNull null],
            setter ? [JSValue valueWithJSValueRef:setter inContext:context.context] : [NSNull null]
        ]];
    }
}

JSCoreInstance::~JSCoreInstance() {
//    JSValue *v = (__bridge JSValue *)value;
//    JSObjectSetPrivate((JSObjectRef)v.JSValueRef, nullptr);
//    CFBridgingRelease(value);
}

Variant JSCoreInstance::apply(const StringName &name, const Variant **params, int count) {
    JSValueRef Obj = (JSValueRef)value;
    JSCoreScript *script = (JSCoreScript *)getScript();
    JSCoreContext *context = ctx(script);
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count; ++i) {
        JSValueRef value = toValue(context.context.JSGlobalContextRef, *params[i]);
        [arr addObject:[JSValue valueWithJSValueRef:value inContext:context.context]];
    }
    JSValue *_Obj = [JSValue valueWithJSValueRef:Obj
                                      inContext:context.context];
    JSValue *res = [_Obj invokeMethod:[NSString stringWithUTF8String:name.str()]
                         withArguments:arr];
    return toVariant(context.context.JSGlobalContextRef, res.JSValueRef);
}
