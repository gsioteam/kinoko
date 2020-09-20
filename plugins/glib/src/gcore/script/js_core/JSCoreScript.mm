
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
@property (nonatomic, strong) JSValue *creator;
@property (nonatomic, strong) JSValue *getset;

- (id)initWithScript:(JSCoreScript *)script;

- (void)setupWithDir:(NSString *)dir;

- (JSValue *)loadModuile:(NSString *)path;

- (JSValue *)call:(JSValue *)Class staticFunction:(const Method *)method arguments:(NSArray *)args;
- (JSValue *)call:(JSValue *)thisObject memberFunction:(const Method *)method arguments:(NSArray *)args;

- (JSValue *)call:(JSValue *)Class staticMethod:(NSString *)name arguments:(JSValue *)args;
- (JSValue *)call:(JSValue *)thisObject memberMethod:(NSString *)name arguments:(JSValue *)args;

@end

@interface JSCacheItem : NSObject

@property (nonatomic, strong) JSValue *value;
@property (nonatomic, assign) Variant variant;

+ (JSCacheItem *)itemWithValue:(JSValue *)value withVariant:(const Variant &)var;

@end

@implementation JSCacheItem

+ (JSCacheItem *)itemWithValue:(JSValue *)value withVariant:(const Variant &)var {
    JSCacheItem *item = [[JSCacheItem alloc] init];
    item.value = value;
    item.variant = var;
    return item;
}

@end

namespace gscript {

    struct ContextInfo {
        map<void*, JSClassRef> managedDataClasses;
    };
    map<JSContextRef, ContextInfo> contexts;

    class JSCoreItem {
        JSManagedValue *managedValue;
    public:
        
        JSCoreItem(JSValue *value) {
            managedValue = [JSManagedValue managedValueWithValue:value];
        }
        
        JSValue *value() {
            return managedValue.value;
        }
    };

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

#define PRIVATE_KEY @"$_"

    bool setPrivateData2(JSValue *object, void *data, void (*destroy)(JSObjectRef object) = nullptr, JSValueRef *handler = nullptr) {
        JSContextRef ctx = object.context.JSGlobalContextRef;
        auto it = contexts.find(ctx);
        if (it != contexts.end()) {
            JSObjectRef tar = JSObjectMake(ctx, getDataClass(it->second, destroy), data);
            if (tar) {
                [object setObject:[JSValue valueWithJSValueRef:tar
                                                     inContext:object.context]
                forKeyedSubscript:PRIVATE_KEY];
                if (handler) *handler = tar;
                return true;
            }
        }
        return false;
    }

    void removePrivateData(JSValue *object) {
        [object setObject:[JSValue valueWithUndefinedInContext:object.context]
        forKeyedSubscript:PRIVATE_KEY];
    }

    void *getPrivateData(JSValue *object) {
        JSContextRef ctx = object.context.JSGlobalContextRef;
        JSValue *value = [object objectForKeyedSubscript:PRIVATE_KEY];
        if (value.isObject) {
            return JSObjectGetPrivate((JSObjectRef)value.JSValueRef);
        }
        return nullptr;
    }

    void onInit(JSContextRef ctx, JSObjectRef object) {
//        NSLog(@"onInit");
    }

    void onDestroyInstance(JSObjectRef object) {
//        NSLog(@"onDestroyInstance");
        JSCoreInstance *mins = (JSCoreInstance *)JSObjectGetPrivate(object);
        if (mins) {
            delete mins;
        }
    }

    void onDestroyClass(JSObjectRef object) {
//        NSLog(@"onDestroyClass");
//        JSCoreClass *mcls = (JSCoreClass *)JSObjectGetPrivate(object);
//        if (mcls) {
//            delete mcls;
//        }
    }

    JSCoreContext *ctx(JSCoreScript *script) {
        return (__bridge JSCoreContext *)script->getContext();
    }

    Variant findCache(NSMutableArray<JSCacheItem *> *cache, JSValue *value) {
        for (JSCacheItem *item in cache) {
            if ([item.value isEqualToObject:value]) {
                return item.variant;
            }
        }
        return Variant::null();
    }

    Variant toVariant(JSValue *value);
    Variant _toVariant(JSValue *value, NSMutableArray<JSCacheItem *> *cache) {
        Variant ret;
        if (value.isNumber) {
            ret = value.toNumber.doubleValue;
        } else if (value.isString || value.isSymbol) {
            ret = value.toString.UTF8String;
        } else if (value.isBoolean) {
            ret = value.toBool;
        } else if (value.isArray) {
            ret = findCache(cache, value);
            if (!ret) {
                int32_t length = [value objectForKeyedSubscript:@"length"].toInt32;
                Array arr;
                for (int i = 0; i < length; ++i) {
                    arr.push_back(_toVariant([value objectAtIndexedSubscript:i], cache));
                }
                ret = arr;
                [cache addObject:[JSCacheItem itemWithValue:value
                                                withVariant:ret]];
            }
            
        } else if (value.isObject) {
            JSContextRef ctx = value.context.JSGlobalContextRef;
            if (JSObjectIsFunction(ctx, (JSObjectRef)value.JSValueRef)) {
                JSCoreScript *script = (JSCoreScript *)getPrivateData(value.context.globalObject);
                JSCoreContext *context = gscript::ctx(script);
                JSValue *cb = [context.convert callWithArguments:@[value]];
                ret = toVariant(cb);
            } else {
                JSCoreInstance *ins = (JSCoreInstance *)getPrivateData(value);
                if (ins) {
                    return ins->getTarget();
                } else {
                    ret = findCache(cache, value);
                    if (!ret) {
                        Map map;
                        JSPropertyNameArrayRef names = JSObjectCopyPropertyNames(ctx, (JSObjectRef)value.JSValueRef);
                        size_t count = JSPropertyNameArrayGetCount(names);
                        for (int i = 0; i < count; ++i) {
                            JSStringRef name = JSPropertyNameArrayGetNameAtIndex(names, i);
                            size_t name_len = JSStringGetMaximumUTF8CStringSize(name);
                            char *c_name = (char *)malloc(name_len * sizeof(char));
                            JSStringGetUTF8CString(name, c_name, name_len);
                            NSString *o_name = [NSString stringWithUTF8String:c_name];
                            map.set(c_name, _toVariant([value objectForKeyedSubscript:o_name], cache));
                            free(c_name);
                        }
                        JSPropertyNameArrayRelease(names);

                        [cache addObject:[JSCacheItem itemWithValue:value
                                                        withVariant:map]];
                        ret = map;
                    }
                    return ret;
                }
            }
        }
        return ret;
    }

    Variant toVariant(JSValue *value) {
        return _toVariant(value, [NSMutableArray array]);
    }

    JSValue* toValue(JSContext *_ctx, const Variant &var) {
        switch (var.getType()) {
            case Variant::TypeChar:
            case Variant::TypeShort:
            case Variant::TypeInt:
            case Variant::TypeLong:
            case Variant::TypeLongLong:
                return [JSValue valueWithInt32:var inContext:_ctx];
                
            case Variant::TypeFloat:
            case Variant::TypeDouble:
                return [JSValue valueWithDouble:var inContext:_ctx];
                
            case Variant::TypeBool:
                return [JSValue valueWithBool:var inContext:_ctx];
            case Variant::TypeStringName: {
                StringName name = var;
                return [JSValue valueWithObject:[NSString stringWithUTF8String:name.str()]
                                      inContext:_ctx];
            }
            case Variant::TypeReference: {
                const gc::Class* cls = var.getTypeClass();
                if (cls->isTypeOf(gc::_String::getClass())) {
                    return [JSValue valueWithObject:[NSString stringWithUTF8String:var.str().c_str()]
                                          inContext:_ctx];
                } else {
                    Ref<Object> obj = var;
                    JSContextRef ctxRef = _ctx.JSGlobalContextRef;
                    JSCoreScript *script = (JSCoreScript *)getPrivateData(_ctx.globalObject);
                    JSCoreInstance *mins = (JSCoreInstance *)obj->findScript(script);
                    if (mins) {
                        return mins->getValue()->value();
                    } else {
                        JSCoreClass *mcls = (JSCoreClass *)script->find(cls);
                        if (mcls) {
                            JSValue *Class = (__bridge JSValue *)mcls->getScriptClass();
                            JSCoreContext *context = ctx(script);
                            JSValue *nObj = [context.creator callWithArguments:@[Class]];
                            if (nObj.isObject) {
                                JSCoreInstance *mins = (JSCoreInstance *)mcls->create(var.get<Object>());
                                JSValueRef handler = nullptr;
                                setPrivateData2(nObj, mins);
                                mins->setValue(new JSCoreItem(nObj));
                                return nObj;
                            }
                            
                        }
                    }
                }
            }
                
            default: break;
        }
        return [JSValue valueWithUndefinedInContext:_ctx];
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
}

@implementation JSCoreContext

- (id)initWithScript:(JSCoreScript *)script {
    self = [super init];
    if (self) {
        _script = script;
        self.modules = [NSMutableDictionary dictionary];
        
        __weak JSCoreContext *that = self;
        _context = [[JSContext alloc] init];
        JSContextRef ctx = _context.JSGlobalContextRef;
        
        self.creator = [_context evaluateScript:@"(function(Cls) {return new Cls();})"];
        self.getset = [_context evaluateScript:@"(function(propertype, name, getter, setter) { Object.defineProperty(propertype, name, {get: getter ? getter : undefined, set: setter ? setter : undefined, configurable: true}) })"];
        
        contexts[ctx] = ContextInfo();
        setPrivateData2(_context.globalObject, script);
        
        [_context setExceptionHandler:^(JSContext *context, JSValue *exception) {
            NSLog(@"JavaScriptContext: \n%@", exception);
        }];
        
        [_context.globalObject setObject:^() {
            NSMutableString *str = [NSMutableString stringWithString:@"[I] "];
            for (JSValue *value in JSContext.currentArguments) {
                [str appendString:value.toString];
            }
            NSLog(@"%@", str);
        } forKeyedSubscript:@"_printInfo"];
        
        [_context.globalObject setObject:^() {
            NSMutableString *str = [NSMutableString stringWithString:@"[W] "];
            for (JSValue *value in JSContext.currentArguments) {
                [str appendString:value.toString];
            }
            NSLog(@"%@", str);
        } forKeyedSubscript:@"_printWarn"];
        
        [_context.globalObject setObject:^() {
            NSMutableString *str = [NSMutableString stringWithString:@"[E] "];
            for (JSValue *value in JSContext.currentArguments) {
                [str appendString:value.toString];
            }
            NSLog(@"%@", str);
        } forKeyedSubscript:@"_printError"];
        
        [_context.globalObject setObject:^(JSValue *Class, NSString *className) {
            JSCoreScript *script = that.script;
            if (script) {
                script->regClass((void *)CFBridgingRetain(Class), className.UTF8String);
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
                return [that call:JSContext.currentThis memberMethod:name arguments:args];
            }
            return nil;
        } forKeyedSubscript:@"_call"];
        [_context.globalObject setObject:^JSValue *(NSString *name, JSValue *args) {
            if (name && args.isArray) {
                return [that call:JSContext.currentThis staticMethod:name arguments:args];
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
    
    Array arr = toVariant(args);
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
    
//    bool res = JSObjectSetPrivate((JSObjectRef)target.JSValueRef, mins);
//    NSLog(@"new Object %@", res ? @"YES": @"NO");
    setPrivateData2(target, mins, onDestroyInstance);
    mins->setValue(new JSCoreItem(target));
}

- (void)destroyObject:(JSValue *)target {
    removePrivateData(target);
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

- (JSValue *)call:(JSValue *)Class staticFunction:(const Method *)method arguments:(NSArray *)arguments {
    JSCoreClass *cls = (JSCoreClass *)getPrivateData(Class);

    Variant ret;
    NSInteger argumentCount = arguments.count;
    if (argumentCount > 0) {
        vector<Variant> vs;
        vs.resize(argumentCount);
        vector<Variant *> args;
        args.resize(argumentCount);
        for (int i = 0; i < argumentCount; ++i) {
            vs[i] = toVariant(arguments[i]);
            args[i] = &vs[i];
        }
        ret = method->call(nullptr, (const Variant **)args.data(), (int)args.size());
    } else {
        ret = method->call(nullptr, nullptr, 0);
    }
    return toValue(Class.context, ret);
}

- (JSValue *)call:(JSValue *)thisObject memberFunction:(const Method *)method arguments:(NSArray *)arguments {
    JSCoreInstance *mins = (JSCoreInstance *)getPrivateData(thisObject);
    
    Variant ret;
    NSInteger argumentCount = arguments.count;
    if (argumentCount > 0) {
        vector<Variant> vs;
        vs.resize(argumentCount);
        vector<Variant *> args;
        args.resize(argumentCount);
        for (int i = 0; i < argumentCount; ++i) {
            vs[i] = toVariant(arguments[i]);
            args[i] = &vs[i];
        }
        ret = method->call(mins->getTarget().get(), (const Variant **)args.data(), (int)args.size());
    } else {
        ret = method->call(mins->getTarget().get(), nullptr, 0);
    }
    return toValue(thisObject.context, ret);
}

- (JSValue *)call:(JSValue *)Class staticMethod:(NSString *)name arguments:(JSValue *)args {
    JSCoreClass *cls = (JSCoreClass *)getPrivateData(Class);
    const Method *method = cls->getNativeClass()->getMethod(name.UTF8String);
    NSInteger len = [args objectForKeyedSubscript:@"length"].toInt32;
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:len];
    for (NSInteger i = 0; i < len; ++i) {
        [arr addObject:[args objectAtIndexedSubscript:i]];
    }
    return [self call:Class staticFunction:method arguments:arr];
}

- (JSValue *)call:(JSValue *)thisObject memberMethod:(NSString *)name arguments:(JSValue *)args {
    JSCoreInstance *mins = (JSCoreInstance *)getPrivateData(thisObject);
    if (mins->getTarget()) {
        const Method *method = mins->getTarget()->getInstanceClass()->getMethod(name.UTF8String);
        NSInteger len = [args objectForKeyedSubscript:@"length"].toInt32;
        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:len];
        for (NSInteger i = 0; i < len; ++i) {
            [arr addObject:[args objectAtIndexedSubscript:i]];
        }
        return [self call:thisObject memberFunction:method arguments:arr];
    }
    return nil;
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
        return toVariant(value);
    }
    return Variant::null();
}

Variant JSCoreScript::runFile(const char *filepath) const {
    if (filepath) {
        JSValue *value = [CTX loadModuile:[NSString stringWithUTF8String:filepath]];
        return toVariant(value);
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
    void *Class = getScriptClass();
    CFBridgingRelease(Class);
}

gc::Variant JSCoreClass::apply(const gc::StringName &name, const gc::Variant **params, int count) const {
    JSValueRef Class = (JSValueRef)getScriptClass();
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:count];
    JSCoreScript *script = (JSCoreScript *)getScript();
    JSCoreContext *context = ctx(script);
    for (int i = 0; i < count; ++i) {
        JSValue* value = toValue(context.context, *params[i]);
        [arr addObject:value];
    }
    JSValue *_Cls = [JSValue valueWithJSValueRef:Class
                                       inContext:context.context];
    JSValue *res = [_Cls invokeMethod:[NSString stringWithUTF8String:name.str()]
                         withArguments:arr];
    return toVariant(res);
}

ScriptInstance *JSCoreClass::makeInstance() const {
    return new JSCoreInstance;
}

void JSCoreClass::bindScriptClass() {
    JSCoreScript *script = (JSCoreScript *)getScript();
    JSValue *Class = (__bridge JSValue *)getScriptClass();
    const gc::Class *cls = getNativeClass();

    JSValueRef ex;
    JSCoreContext *context = ctx(script);
    JSContextRef _ctx = context.context.JSGlobalContextRef;
    setPrivateData2(Class, this, onDestroyClass);
    JSValue *prototype = [Class objectForKeyedSubscript:@"prototype"];
    
    const pointer_map &methods = cls->getMethods();
    __weak JSCoreContext *weakContext = context;
    for (auto it = methods.begin(); it != methods.end(); ++it) {
        StringName name(it->first);
        const Method *method = (const Method *)it->second;
        
        switch (method->getType()) {
            case Method::Static: {
                [Class setObject:^() {
                    return [weakContext call:JSContext.currentThis
                              staticFunction:method
                                   arguments:JSContext.currentArguments];
                } forKeyedSubscript:[NSString stringWithUTF8String:name.str()]];
                break;
            }
            case Method::Member:
            case Method::ConstMb: {
                [prototype setObject:^() {
                    return [weakContext call:JSContext.currentThis
                              memberFunction:method
                                   arguments:JSContext.currentArguments];
                } forKeyedSubscript:[NSString stringWithUTF8String:name.str()]];
                break;
            }
            default: break;
        }
    }
    
    JSValue *undifined = [JSValue valueWithUndefinedInContext:context.context];
    auto& properties = cls->getProperties();
    for (auto it = properties.begin(), _e = properties.end(); it != _e; ++it) {
        StringName name(it->first);
        const Property *property = (const Property *)it->second;
        JSValue *getter = nil, *setter = nil;
        if (property->getGetter()) {
            const StringName &name = property->getGetter()->getName();
            getter = [prototype objectForKeyedSubscript:[NSString stringWithUTF8String:name.str()]];
        }
        if (property->getSetter()) {
            const StringName &name = property->getSetter()->getName();
            setter = [prototype objectForKeyedSubscript:[NSString stringWithUTF8String:name.str()]];
        }
        
        [context.getset callWithArguments:@[
            prototype,
            [NSString stringWithUTF8String:name.str()],
            getter ? getter : undifined,
            setter ? setter : undifined
        ]];
    }
}

JSCoreInstance::~JSCoreInstance() {
    JSValue *val = value->value();
    JSValue *object = [val objectForKeyedSubscript:PRIVATE_KEY];
    if (object.isObject) {
        JSObjectRef objRef = (JSObjectRef)object.JSValueRef;
        JSObjectSetPrivate(objRef, nullptr);
    }
    if (value) delete value;
}

Variant JSCoreInstance::apply(const StringName &name, const Variant **params, int count) {
    JSCoreScript *script = (JSCoreScript *)getScript();
    JSCoreContext *context = ctx(script);
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count; ++i) {
        JSValue* value = toValue(context.context, *params[i]);
        [arr addObject:value];
    }
    
    JSValue *_Obj = value->value();
    JSValue *func = [_Obj objectForKeyedSubscript:[NSString stringWithUTF8String:name.str()]];
//    vector<JSValueRef> args;
//    for (int i = 0; i < count; ++i) {
//        args.push_back([arr[i] JSValueRef]);
//    }
//    JSValueRef ref = JSObjectCallAsFunction(_Obj.context.JSGlobalContextRef,
//                           (JSObjectRef)func.JSValueRef,
//                           (JSObjectRef)_Obj.JSValueRef,
//                           arr.count,
//                           args.data(),
//                           nil);
//    JSValue *res = [JSValue valueWithJSValueRef:ref
//                                      inContext:_Obj.context];
    
    JSValue *res = [_Obj invokeMethod:[NSString stringWithUTF8String:name.str()]
                         withArguments:arr];
    return toVariant(res);
}
