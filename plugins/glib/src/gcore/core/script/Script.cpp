//
// Created by gen on 16/9/6.
//

#include "Script.h"
#include "ScriptClass.h"
#include "ScriptInstance.h"
#include "../Base.h"
#include "../runtime.h"
#include "../Ref.h"
#include "../Callback.h"
#include <sstream>

using namespace gc;
using namespace std;

pointer_set Script::scripts;

ScriptClass* Script::findOrCreate(const StringName &fullname, bool &create) {
    auto it = classes.find(fullname);
    if (it == classes.end()) {
        const Class *cls = ClassDB::getInstance()->find(fullname);
        if (cls) {
            ScriptClass *scls = makeClass();
            scls->setNativeClass(cls);
            scls->setScript(this);
            classes[fullname] = (void*)scls;
            create = true;
            return scls;
        }
        create = false;
        return NULL;
    }
    create = false;
    return (ScriptClass *)it->second;
}

void Script::clear() {
    for (auto it = instances.begin(), _e = instances.end(); it != _e; ++it) {
        ScriptInstance *ins = (ScriptInstance *)*it;
        ins->removed = true;
        delete ins;
    }
    instances.clear();
    for (auto it = classes.begin(), _e = classes.end(); it != _e; ++it) {
        delete (ScriptClass*)it->second;
    }
    classes.clear();
}

Script::~Script() {
    clear();
    scripts.erase(this);
}

ScriptClass *Script::find(const StringName &fullname) const {
    auto it = classes.find(fullname);
    if (it == classes.end()) {
        return NULL;
    }
    return (ScriptClass*)it->second;
}

ScriptClass *Script::find(const Class *cls) const {
    auto it = classes.find(cls->getFullname());
    const Class *parent = cls->getParent();
    while (it == classes.end() && parent) {
        it = classes.find(parent->getFullname());
        parent = parent->getParent();
    }
    if (it == classes.end()) {
        return NULL;
    }
    return (ScriptClass*)it->second;
}

Script::Script(const StringName &name) : name(name) {
    scripts.insert(this);
}

//void Script::addFunction(const StringName &name, const gc::Callback &function) {
////    defineFunction(name, function);
//}

gc::Variant Script::runFile(const char *filepath) const {
    FILE *file = fopen(filepath, "r");
    if (file) {
        std::stringstream ss;
#define B_SIZW 4096
        char buf[B_SIZW];
        size_t readed = 0;
        while ((readed = fread(buf, 1, B_SIZW, file)) > 0) {
            ss.write(buf, readed);
        }
        fclose(file);
        std::string str = ss.str();
        return runScript(str.c_str(), filepath);
    }else {
        LOG(e, "Can not open file");
        return Variant::null();
    }
}

ScriptClass* Script::regClass(void *script_cls, const gc::StringName &name) {
    bool create;
    ScriptClass *scls = findOrCreate(name, create);
    if (create) {
        scls->script_cls = script_cls;
        scls->bindScriptClass();
    }
    return scls;
}

void Script::addInstance(gc::ScriptInstance *ins) {
    instances.insert(ins);
}

void Script::removeInstance(gc::ScriptInstance *ins) {
    instances.erase(ins);
}

Script * Script::get(const StringName &name) {
    for (auto it = scripts.begin(), _e = scripts.end(); it != _e; ++it) {
        Script *src = (Script *)*it;
        if (src->name == name) {
            return src;
        }
    }
    return nullptr;
}

Variant ScriptClass::call(const StringName &name, const Variant **params, int count) const {
    const Method *mtd = cls->getMethod(name);
    if (mtd && mtd->getType() == Method::Static) return mtd->call(NULL, params, count);
    return Variant::null();
}

ScriptInstance* ScriptClass::newInstance(const Variant **params, int count) {
    if (cls->isTypeOf(Object::getClass())) {
        Object *ref = (Object*)cls->instance();
        const Method *init = cls->getInitializer();
        if (init) init->call(ref, params, count);
        ScriptInstance *sin = makeInstance();
        sin->setScript(script);
        sin->setMiddleClass(const_cast<ScriptClass*>(this));
        if (cls->isTypeOf(Base::getClass())) {
            ref->addScript(sin);
        }
        sin->setTarget(ref);
        script->addInstance(sin);
        return sin;
    }
    LOG(w, "Wrong Class Type %s", cls ? cls->getName(): "null");
    return nullptr;
}

ScriptInstance *ScriptClass::get(Object *target) const {
    return script->getScriptInstance(target);
}

ScriptInstance* ScriptClass::create(Object *target) const {
    const Class *cls = target->getInstanceClass();
    if (cls->isTypeOf(Object::getClass())) {
        ScriptInstance *ins = makeInstance();
        ins->setScript(script);
        ins->setMiddleClass(const_cast<ScriptClass*>(this));
        ins->setTarget(target);
        target->addScript(ins);
        script->addInstance(ins);
        return ins;
    }else {
        LOG(w, "%s is not Object", cls->getName());
        return NULL;
    }
}

Variant ScriptInstance::call(const StringName &name, const Variant **params, int count) const {
    if (target) {
        const Class *ncls = cls->getNativeClass();
        const Method *mtd = ncls->getMethod(name);
        if (mtd) {
            return mtd->call((void*)getTarget(), params, count);
        }
    }
    return Variant::null();
}

Variant ScriptInstance::get(const StringName &name) const {
    if (target) {
        const Property *pro = cls->getNativeClass()->getProperty(name);
        if (pro) {
            return pro->get(getTarget().get());
        }
    }
    return Variant::null();
}

void ScriptInstance::set(const StringName &name, const Variant &val) const {
    if (target) {
        const Property *pro = cls->getNativeClass()->getProperty(name);
        if (pro) {
            pro->set(getTarget().get(), val);
        }
    }
}

ScriptInstance::~ScriptInstance() {
    if (target) {
        ((Object*)target)->removeScript(this);
    }
    if (single_class && cls) {
        delete cls;
    }
    if (!removed) script->removeInstance(this);
}

