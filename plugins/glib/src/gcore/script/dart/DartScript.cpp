//
// Created by Gen2 on 2020/5/18.
//

#include "DartScript.h"
#include <core/String.h>
#include <core/Map.h>

using namespace gscript;
using namespace gc;
using namespace std;

DartScript *DartScript::ins = nullptr;

namespace gscript {

    enum NativeType{
        TypeNull = 0,
        TypeInt = 1,
        TypeDouble = 2,
        TypeObject = 3,
        TypeString = 4,
        TypeBoolean = 5,
        TypePointer = 6,
    };

    struct NativeTarget {
        uint8_t type = TypeNull;
        uint64_t int_value;
        double double_value;
        void *pointer_value;
        uint8_t release = false;

        ~NativeTarget() {
            if (release) {
                switch (type) {
                    case TypeString: {
                        char *str = (char *)pointer_value;
                        free(str);
                        break;
                    }
                    case TypeObject: {
                        Object *base = (Object *)pointer_value;
                        delete base;
                        break;
                    }
                }
            }
        }
    };
    StringName DartLanguage("dart");


    Variant dart_toVariant(NativeTarget *target) {
        switch (target->type) {
            case TypeInt: {
                return target->int_value;
            }
            case TypeDouble: {
                return target->double_value;
            }
            case TypeObject: {
                DartInstance *instance = (DartInstance *)target->pointer_value;
                return instance->getTarget();
            }
            case TypeString: {
                const char *str = (const char *)target->pointer_value;
                return str;
            }
            case TypeBoolean: {
                return (bool)target->int_value;
            }
            case TypePointer: {
                return target->pointer_value;
            }
        }
        return Variant::null();
    }

    void dart_toDart(const Variant &variant, NativeTarget *target) {
        switch (variant.getType()) {
            case Variant::TypeBool: {
                target->type = TypeBoolean;
                target->int_value = variant;
                break;
            }
            case Variant::TypeChar:
            case Variant::TypeInt:
            case Variant::TypeShort:
            case Variant::TypeLong:
            case Variant::TypeLongLong:
            {
                target->type = TypeInt;
                target->int_value = variant;
                break;
            }
            case Variant::TypeFloat:
            case Variant::TypeDouble:
            {
                target->type = TypeDouble;
                target->double_value = variant;
                break;
            }
            case Variant::TypeStringName: {
                StringName name = variant;
                target->type = TypeString;
                target->pointer_value = (void*)name.str();
                break;
            }
            case Variant::TypeReference: {
                const Class *cls = variant.getTypeClass();
                if (cls->isTypeOf(_String::getClass())) {
                    const char *str = variant;
                    int len = strlen(str);
                    char *cstr = (char *)malloc(len + 1);
                    strcpy(cstr, str);
                    cstr[len] = 0;
                    target->type = TypeString;
                    target->release = true;
                    target->pointer_value = (void *)cstr;
                } else {
                    Ref<Object> obj = variant;
                    DartInstance *ins = (DartInstance *)obj->findScript(DartLanguage);
                    if (ins) {
                        target->type = TypeObject;
                        target->pointer_value = ins;
                    } else {
                        const Class *cls = obj->getInstanceClass();
                        ins = (DartInstance *)DartScript::instance()->find(cls)->create(obj);
                        if (ins) {
                            target->type = TypeObject;
                            target->pointer_value = ins;
                        }
                    }
                }
                break;
            }
            case Variant::TypePointer: {
                target->type = TypePointer;
                target->pointer_value = (void *)variant;
                break;
            }
            default: {
                target->type = TypeNull;
            }
        }
    }
}
DartScript::DartScript() : Script(DartLanguage) {
}

DartScript::~DartScript() {
}

void DartScript::setup(gscript::Dart_CallClass call_class,
                       gscript::Dart_CallInstance call_instance,
                       Dart_CreateFromNative from_native) {
    if (ins) {
        LOG(e, "dart engine already running!");
        return;
    }
    ins = new DartScript();
    ins->handlers.to_class = call_class;
    ins->handlers.to_instance = call_instance;
    ins->handlers.from_native = from_native;
}

void DartScript::destroy() {
    if (ins) {
        delete ins;
        ins = nullptr;
    }
}

bool DartScript::alive() {
    return ins;
}

DartScript* DartScript::instance() {
    return ins;
}

gc::Variant DartScript::runScript(const char *script, const char *filename) const {
    LOG(e, "Not support run script.");
    return Variant::null();
}

void DartScript::defineFunction(const gc::StringName &name, const gc::Callback &function) {
    LOG(e, "Not support define function!");
}

void DartClass::bindScriptClass() {

}

gc::ScriptInstance* DartClass::create(gc::Object *target) const {
    DartInstance *ins = (DartInstance *)ScriptClass::create(target);
    int state = ((DartScript*)getScript())->handlers.from_native(this, ins);
    if (state == 0) {
        return ins;
    } else {
        delete ins;
        return nullptr;
    }
}

Variant DartClass::apply(const gc::StringName &name, const gc::Variant **argv, int length) const {
    if (!DartScript::alive()) return Variant::null();
    vector<NativeTarget> pargv(length);
    pargv.resize(length);
    for (int i = 0; i < length; ++i) {
        dart_toDart(*argv[i], &pargv.at(i));
    }

    DartScript *script = (DartScript *)getScript();
    NativeTarget ret;
    if (script->handlers.to_class) {
        script->handlers.to_class(this, name.str(), pargv.data(), length, &ret);
    }
    return dart_toVariant(&ret);
}

Variant DartInstance::apply(const gc::StringName &name, const gc::Variant **argv, int length) {
    if (!DartScript::alive()) return Variant::null();
    vector<NativeTarget> pargv(length);
    pargv.resize(length);
    for (int i = 0; i < length; ++i) {
        dart_toDart(*argv[i], &pargv.at(i));
    }

    DartScript *script = (DartScript *)getScript();
    NativeTarget ret;
    if (script->handlers.to_instance) {
        script->handlers.to_instance(this, name.str(), pargv.data(), length, &ret);
    }
    return dart_toVariant(&ret);
}


DART_EXPORT
DartClass *dart_bindClass(const char *name) {
    return (DartClass*)DartScript::instance()->regClass(nullptr, name);
}

DART_EXPORT
DartInstance* dart_createObject(DartClass *type, NativeTarget *argv, int32_t length) {
    variant_vector vars;
    vector<Variant*> params;
    vars.resize(length);
    params.resize(length);
    for (int i = 0; i < length; ++i) {
        vars[i] = dart_toVariant(argv + i);
        params[i] = &vars.at(i);
    }
    return (DartInstance *)type->newInstance((const Variant **)params.data(), length);
}

DART_EXPORT
void dart_freeObject(DartInstance* instance) {
    if (DartScript::instance())
        delete instance;
}

DART_EXPORT
NativeTarget *dart_callObject(DartInstance* instance, const char *method, NativeTarget *argv, int32_t length) {
    Variant res;
    variant_vector vars;
    vector<Variant *> params;
    vars.resize(length);
    params.resize(length);
    for (int i = 0; i < length; ++i) {
        vars[i] = dart_toVariant(argv + i);
        params[i] = &vars.at(i);
    }

    Variant var = instance->getTarget();
    if (var.isRef()) {
        var->call(method, &res, (const Variant **)params.data(), length);
    }
    NativeTarget *result = new NativeTarget();
    dart_toDart(res, result);
    return result;
}

DART_EXPORT
NativeTarget *dart_callClass(DartClass* dartcls, const char *method, NativeTarget *argv, int32_t length) {
    Variant res;
    variant_vector vars;
    vector<Variant *> params;
    vars.resize(length);
    params.resize(length);
    for (int i = 0; i < length; ++i) {
        vars[i] = dart_toVariant(argv + i);
        params[i] = &vars.at(i);
    }

    const Class *cls = dartcls->getNativeClass();
    res = cls->call(method, nullptr, (const Variant **)params.data(), length);
    NativeTarget *result = new NativeTarget();
    dart_toDart(res, result);
    return result;
}

DART_EXPORT
void dart_freeResult(NativeTarget *result) {
    delete result;
}