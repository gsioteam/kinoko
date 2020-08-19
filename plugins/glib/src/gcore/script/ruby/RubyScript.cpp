//
//  RubyScript.cpp
//  hirender_iOS
//
//  Created by Gen on 16/9/28.
//  Copyright © 2016年 gen. All rights reserved.
//

#include <mruby/compile.h>
#include <mruby/string.h>
#include <mruby/class.h>
#include <mruby/variable.h>
#include <mruby/array.h>
#include <mruby/string.h>
#include <mruby/proc.h>
#include <mruby/data.h>
#include <mruby/array.h>
#include <mruby/hash.h>
#include <mruby/error.h>
#include <core/Array.h>
#include <core/runtime.h>
#include <core/script/NativeObject.h>
#include <core/String.h>
#include <core/FixType.h>
#include <core/Map.h>
#include "RubyScript.h"
#include <core/Callback.h>

#define SCRIPT ((RubyScript*)getScript())

using namespace gscript;
using namespace std;

mrb_sym sym_native_class;
mrb_sym sym_native_instance;

const char debug_string[] = "begin\n"
"  load('{{path}}')\n"
"rescue Exception => e\n"
"  p e.message\n"
"  print e.backtrace.join(\"\\n\")\n"
"end";

mrb_data_type *ruby_data_type = NULL;

void ruby_instance_free(mrb_state *mrb, void *data) {
    delete (RubyInstance*)data;
}

const mrb_data_type *ruby_type() {
    if (!ruby_data_type) {
        ruby_data_type = (mrb_data_type *)malloc(sizeof(mrb_data_type));
        ruby_data_type->struct_name = "RubyInstance";
        ruby_data_type->dfree = ruby_instance_free;
    }
    return ruby_data_type;
}



mrb_value ruby_h2r(mrb_state *mrb, const gc::Variant &v) {
    gc::Variant::Type type = v.getType();
    switch (type) {
        case gc::Variant::TypeNull: {
            return mrb_nil_value();
        }
        case gc::Variant::TypeBool: {
            return mrb_bool_value((bool)v);
        }
        case gc::Variant::TypeChar:
        case gc::Variant::TypeShort:
        case gc::Variant::TypeInt:
        case gc::Variant::TypeLong:
        case gc::Variant::TypeLongLong: {
            return mrb_fixnum_value(v);
        }
        case gc::Variant::TypeFloat:
        case gc::Variant::TypeDouble: {
            return mrb_float_value(mrb, v);
        }
        case gc::Variant::TypeStringName: {
            return mrb_symbol_value(mrb_intern_cstr(mrb, v));
        }
        case gc::Variant::TypeObject: {
            return mrb_cptr_value(mrb, v);
        }
        case gc::Variant::TypeReference: {
            const gc::Class *typeclass = v.getTypeClass();
            if (typeclass->isTypeOf(gc::_String::getClass())) {
                string str = v;
                return mrb_str_new_cstr(mrb, str.c_str());
            }
            RubyScript *script = (RubyScript*)mrb->ud;
            RubyClass *mcls = (RubyClass*)script->find(typeclass);
            if (mcls) {
                RubyInstance *mins = (RubyInstance*)mcls->get(v.ref());
                if (mins) {
                    return mrb_obj_value(mins->getScriptInstance());
                }
                struct RClass *rcls = mcls->getRubyClass();
                mrb_value obj = mrb_obj_new(mrb, rcls, 0, NULL);
                mins = (RubyInstance*)mcls->create(v.ref());
                mins->setScriptInstance(mrb_obj_ptr(obj));

                struct RData* data = mrb_data_object_alloc(mrb, mrb->object_class, mins, ruby_type());
                mrb_iv_set(mrb, obj, sym_native_instance, mrb_obj_value(data));
                return obj;
            }
        }
        case gc::Variant::TypePointer: {
            //return mrb_cptr_value(mrb, v);
        }
        case gc::Variant::TypeMemory: {
            //TODO Something for memory type
        }
    }
    return mrb_nil_value();
}

gc::Variant ruby_r2h(mrb_state *mrb, mrb_value v) {
    switch (v.tt) {
        case MRB_TT_FALSE:
            return gc::Variant(false);
        case MRB_TT_FREE:
            return gc::Variant::null();
        case MRB_TT_TRUE:
            return gc::Variant(true);
        case MRB_TT_FIXNUM:
            return gc::Variant(mrb_int(mrb, v));
        case MRB_TT_SYMBOL:
            return gc::Variant(mrb_sym2name(mrb, mrb_symbol(v)));
        case MRB_TT_FLOAT:
            return gc::Variant(mrb_float(v));
        case MRB_TT_CPTR:
            return gc::Variant((void*)mrb_cptr(v));
        case MRB_TT_OBJECT:
        {
            mrb_value val = mrb_attr_get(mrb, v, sym_native_instance);
            if (mrb_nil_p(val)) {
                return gc::Variant::null();
            }else {
                RubyInstance *cinst = (RubyInstance *)DATA_PTR(val);
                if (cinst)
                    return cinst->getTarget();
                return gc::Variant::null();
            }
        }
        case MRB_TT_CLASS:
        case MRB_TT_MODULE:
        case MRB_TT_ICLASS:
        case MRB_TT_SCLASS:
        {
            mrb_value val = mrb_iv_get(mrb, v, sym_native_class);
            if (mrb_nil_p(val)) {
                return gc::Variant::null();
            }else {
                RubyClass *ccls = (RubyClass *)mrb_cptr(val);
                return gc::Variant(ccls);
            }
        }
        case MRB_TT_ARRAY:
        {
            mrb_int l = ARY_LEN(mrb_ary_ptr(v));
            vector<gc::Variant> vs;
            vs.reserve(l);
            for (int i = 0; i < l; ++i) {
                vs.push_back(ruby_r2h(mrb, mrb_ary_ref(mrb, v, i)));
            }
            return gc::Variant(gc::Array(vs));
        }
        case MRB_TT_STRING:
        {
            return gc::Variant(mrb_str_to_cstr(mrb, v));
        }
        case MRB_TT_HASH:
        {
            mrb_value keys = mrb_hash_keys(mrb, v);
            mrb_int l = ARY_LEN(mrb_ary_ptr(keys));
            gc::Map map;
            for (mrb_int i = 0; i < l; ++i) {
                mrb_value key = mrb_ary_ref(mrb, keys, i);
                mrb_value value = mrb_hash_get(mrb, v, key);
                if (key.tt != MRB_TT_STRING) {
                    key = mrb_str_to_str(mrb, key);
                }
                map->set(mrb_str_to_cstr(mrb, key), ruby_r2h(mrb, value));
            }
            return map;
        }

        default:
            // TODO hash proc
            return gc::Variant::null();
    }
}

RubyClass *ruby_find_class(mrb_state *mrb, RClass *rcls) {
    RClass *cls = rcls;
    while (cls) {
        mrb_value val = mrb_iv_get(mrb, mrb_obj_value(cls), sym_native_class);
        if (!mrb_nil_p(val)) {
            return (RubyClass *)mrb_cptr(val);
        }
        cls = cls->super;
    }
    return nullptr;
}

mrb_value ruby_native_initialize(mrb_state *mrb, mrb_value obj) {
    RClass *rcls = mrb_class(mrb, obj);
    RubyClass *mcls = ruby_find_class(mrb, rcls);
    if (mcls) {
        int count = mrb_get_argc(mrb);
        if (count >= 1) {
            gc::Array arr = ruby_r2h(mrb, mrb->c->stack[1]);
            if (arr) {
                size_t len = arr.size();
                const gc::Variant **ps = (const gc::Variant **)malloc(len * sizeof(gc::Variant *));
                for (int i = 0; i < len; ++i) {
                    ps[i] = &arr->vec().at(i);
                }
                RubyInstance *mins = (RubyInstance *)mcls->newInstance(ps, len);
                free(ps);
                mins->setScriptInstance(mrb_obj_ptr(obj));
                struct RData* data = mrb_data_object_alloc(mrb, mrb->object_class, mins, ruby_type());
                mrb_iv_set(mrb, obj, sym_native_instance, mrb_obj_value(data));
            }
        }
    }
    return mrb_top_self(mrb);
}

mrb_value ruby_initialize(mrb_state *mrb, mrb_value obj) {
    return mrb_top_self(mrb);
}

mrb_value ruby_native_class(mrb_state *mrb, mrb_value cls) {
    mrb_value name;
    mrb_get_args(mrb, "S", &name);
    RubyScript *script = (RubyScript*)mrb->ud;
    if (script) {
        struct RClass *rcls = mrb_class_ptr(cls);
        script->regClass(rcls, RSTRING_PTR(name));
    }
    return name;
}

mrb_value ruby_call_i(mrb_state *mrb, mrb_value ins) {
    mrb_value val = mrb_iv_get(mrb, ins, sym_native_instance);
    if (mrb_bool(val)) {
        RubyInstance *mins = (RubyInstance*)DATA_PTR(val);
        if (mins && mins->getTarget()) {
            mrb_value m_name = mrb->c->stack[1];
            
            const char* name = mrb_sym2name(mrb, mrb_obj_to_sym(mrb, m_name));
            
            const gc::Class *ncls = mins->getMiddleClass()->getNativeClass();
            const gc::Method *method = ncls->getMethod(name);
            if (!method) {
                string std_name(name);
                const gc::Property *property = ncls->getProperty(std_name.c_str());
                if (property) {
                    method = property->getGetter();
                }
                if (method == NULL && std_name[std_name.size()-1] == '=') {
                    std_name.pop_back();
                    const gc::Property *property = ncls->getProperty(std_name.c_str());
                    if (property) {
                        method = property->getSetter();
                    }
                }
            }
            
            if (method) {
                mrb_value array = mrb->c->stack[2];
                int len = ARY_LEN(mrb_ary_ptr(array));
                if (len) {
                    gc::Variant *vs = new gc::Variant[len];
                    const gc::Variant **ps = (const gc::Variant **)malloc(len * sizeof(gc::Variant *));
                    for (int i = 0; i < len; ++i) {
                        vs[i] = ruby_r2h(mrb, mrb_ary_ref(mrb, array, i));
                        ps[i] = &vs[i];
                    }
                    mrb_value ret = ruby_h2r(mrb, method->call(mins->getTarget().get(), ps, len));
                    delete [] vs;
                    free(ps);
                    return ret;
                }else {
                    return ruby_h2r(mrb, method->call(mins->getTarget().get(), NULL, 0));
                }
            }
        }
    }
    return mrb_nil_value();
}

mrb_value ruby_call_c(mrb_state *mrb, mrb_value cls) {
//    struct RClass *rcls = mrb_class(mrb, cls);
    mrb_value val = mrb_iv_get(mrb, cls, sym_native_class);
    if (!mrb_nil_p(val)) {
        RubyClass *mcls = (RubyClass *)mrb_cptr(val);
        if (mcls) {
            mrb_value m_name = mrb->c->stack[1];
            const char* name = mrb_sym2name(mrb, mrb_obj_to_sym(mrb, m_name));
            mrb_value array = mrb->c->stack[2];
            int len = ARY_LEN(mrb_ary_ptr(array));
            if (len) {
                gc::Variant *vs = new gc::Variant[len];
                const gc::Variant **ps = (const gc::Variant **)malloc((len) * sizeof(gc::Variant *));
                for (int i = 0; i < len; ++i) {
                    vs[i] = ruby_r2h(mrb, mrb_ary_ref(mrb, array, i));
                    ps[i] = &vs[i];
                }
                mrb_value ret = ruby_h2r(mrb, mcls->call(name, ps, len));
                delete [] vs;
                free(ps);
                return ret;
            }else {
                return ruby_h2r(mrb, mcls->call(name, NULL, 0));
            }
        }
    }
    return mrb_nil_value();
}

mrb_value ruby_call_class(mrb_state *mrb, mrb_value cls) {
//    struct RClass *rcls = mrb_class(mrb, cls);
    mrb_value val = mrb_iv_get(mrb, cls, sym_native_class);
    if (mrb_bool(val)) {
        
        RubyClass *scls = (RubyClass *)mrb_cptr(val);
        int count = mrb_get_argc(mrb);
        if (count > 0) {
            gc::Variant *vs = new gc::Variant[count];
            const gc::Variant **ps = (const gc::Variant **)malloc(count * sizeof(gc::Variant *));
            for (int i = 0; i < count; ++i) {
                vs[i] = ruby_r2h(mrb, mrb->c->stack[1 + i]);
                ps[i] = &vs[i];
            }
            mrb_value ret = ruby_h2r(mrb, scls->call(mrb_sym2name(mrb, mrb_get_mid(mrb)), ps, count));
            delete [] vs;
            free(ps);
            return ret;
        }else {
            return ruby_h2r(mrb, scls->call(mrb_sym2name(mrb, mrb_get_mid(mrb)), NULL, 0));
        }
    }
    return mrb_nil_value();
}
mrb_value ruby_call_instance(mrb_state *mrb, mrb_value ins) {
    mrb_value val = mrb_iv_get(mrb, ins, sym_native_instance);
    if (mrb_bool(val)) {
        RubyInstance *mins = (RubyInstance*)DATA_PTR(val);
        if (mins) {
            int count = mrb_get_argc(mrb);
            if (count == 0) {
                return ruby_h2r(mrb, mins->call(mrb_sym2name(mrb, mrb_get_mid(mrb)), NULL, 0));
            }else {
                gc::Variant *vs = new gc::Variant[count];
                const gc::Variant **ps = (const gc::Variant **)malloc(count * sizeof(gc::Variant *));
                for (int i = 0; i < count; ++i) {
                    vs[i] = ruby_r2h(mrb, mrb->c->stack[1 + i]);
                    ps[i] = &vs[i];
                }
                mrb_value ret = ruby_h2r(mrb, mins->call(mrb_sym2name(mrb, mrb_get_mid(mrb)), ps, count));
                delete [] vs;
                free(ps);
                return ret;
            }
        }
    }
    return mrb_nil_value();
}

mrb_value ruby_get_instance(mrb_state *mrb, mrb_value ins) {
    mrb_value val = mrb_iv_get(mrb, ins, sym_native_instance);
    RubyInstance *mins = (RubyInstance*)DATA_PTR(val);
    if (mins) {
        return ruby_h2r(mrb, mins->get(mrb_sym2name(mrb, mrb_get_mid(mrb))));
    }
    return mrb_nil_value();
}

mrb_value ruby_set_instance(mrb_state *mrb, mrb_value ins) {
    mrb_value val = mrb_iv_get(mrb, ins, sym_native_instance);
    RubyInstance *mins = (RubyInstance*)DATA_PTR(val);
    string name(mrb_sym2name(mrb, mrb_get_mid(mrb)));
    if (mrb_bool(val)) {
        name.pop_back();
        if (mins) {
            mins->set(name.c_str(), ruby_r2h(mrb, mrb->c->stack[1]));
        }
    }else {
        LOG(w, "No native instance found.");
    }
    // 添加一个引用.
    mrb_iv_set(mrb, ins, mrb_intern_cstr(mrb, name.c_str()), mrb->c->stack[1]);
    return mrb->c->stack[1];
}

bool RubyScript::setup_handler = false;

void RubyScript::printHandler(const char *str, size_t len) {
    string stdstr;
    stdstr.resize(len);
    memcpy((char *)stdstr.data(), str, len);
    LOG(i, "%s", stdstr.c_str());
}

RubyScript::RubyScript() : Script("ruby"), mrb(NULL) {
    if (!setup_handler) {
        setup_handler = true;
        mrb_set_print_handler(printHandler);
    }
    reset();
}

RubyScript::~RubyScript() {
    mrb_close(mrb);
}

void RubyScript::_setup(const char *root) const {
    string str("$LOAD_PATH = ['");
    str += root;
    str += "']";
    mrb_load_string(mrb, str.c_str());
    string path = root;
    path += "/env.rb";
    runFile(path.c_str());
}

void RubyScript::setup(const char *root) {
    context_root = root;
    _setup(root);
}

void RubyScript::reset() {
    if (mrb)
        mrb_close(mrb);
        
    mrb = mrb_open();
    mrb->ud = this;
    sym_native_class = mrb_intern_cstr(mrb, "NATIVE_CLASS");
    sym_native_instance = mrb_intern_cstr(mrb, "native_instance");
    mrb_define_class_method(mrb, mrb->object_class, "native", &ruby_native_class, MRB_ARGS_REQ(1));
    mrb_define_method(mrb, mrb->object_class, "native_call", &ruby_call_i, MRB_ARGS_REQ(2));

    if (!context_root.empty())
        _setup(context_root.c_str());
    regClass(mrb->object_class, gc::Object::getClass()->getFullname());
}

void mruby_print(mrb_state *mrb, mrb_value exc) {
//    mrb_p(mrb, exc);
    mrb_value val = mrb_funcall(mrb, exc, "inspect", 0);
    string mstr = mrb_string_cstr(mrb, val);
    mrb_value backtrace = mrb_funcall(mrb, exc, "backtrace", 0);
    if (mrb_array_p(backtrace)) {
        mrb_value trace = mrb_funcall(mrb, backtrace, "join", 1, mrb_str_new_cstr(mrb, "\n"));
        mstr += "\n";
        mstr += mrb_string_cstr(mrb, trace);
    }
    LOG(e, "%s", mstr.c_str());
}

void RubyScript::addEnvPath(const char *path) {
    string script = "$LOAD_PATH |= []\n$LOAD_PATH << '";
    script += path;
    script += "'";
    mrb_load_string(mrb, script.c_str());
}

gc::Variant RubyScript::runFile(const char *filepath) const {
    FILE *file = fopen(filepath, "rb");
    if (file) {
        mrb_value val = mrb_load_file(mrb, file);
        fclose(file);
        if (mrb->exc) {
            mruby_print(mrb, mrb_obj_value(mrb->exc));
            return gc::Variant::null();
        }
        return ruby_r2h(mrb, val);
    } else {
        LOG(i, "Can not open %s", filepath);
        return gc::Variant::null();
    }
}

gc::Variant RubyScript::runScript(const char *script, const char *filename) const {
    if (mrb->exc) mrb->exc = NULL;
    mrb_value val = mrb_load_string(mrb, script);
    if (mrb->exc) {
        mruby_print(mrb, mrb_obj_value(mrb->exc));
        mrb->exc = NULL;
        return gc::Variant::null();
    }
    return ruby_r2h(mrb, val);
}

gc::Variant RubyScript::_apply(const mrb_value &value, const gc::StringName &name, const gc::Variant **params, int count) {
    if (mrb->exc) mrb->exc = NULL;
    if (mrb_respond_to(mrb, value, mrb_intern_cstr(mrb, name.str()))) {
        mrb_value *vs = (mrb_value *)malloc(count * sizeof(mrb_value));
        for (int i = 0; i < count; ++i) {
            vs[i] = ruby_h2r(mrb, *params[i]);
        }
        mrb_value ret = mrb_funcall_argv(mrb, value, mrb_intern_cstr(mrb, name.str()), count, vs);
        free(vs);
        if (ret.tt == MRB_TT_EXCEPTION) {
            mruby_print(mrb, ret);
            mrb->exc = NULL;
        }
        return ruby_r2h(mrb, ret);
    }else {
        LOG(w, "can not apply %s", name.str());
    }
    return gc::Variant::null();
}

gc::Variant RubyScript::apply(const gc::StringName &name, const gc::Variant **params, int count) {
    return _apply(mrb_obj_value(mrb->top_self), name, params, count);
}

gc::ScriptClass *RubyScript::makeClass() const {
    return new RubyClass;
}

gc::ScriptInstance *RubyScript::newBuff(const string &cls_name, gc::Object *target, const gc::Variant **params, int count) {
    return newBuff(mrb_class_get(mrb, cls_name.c_str()), target, params, count);
}


RubyInstance *RubyScript::newBuff(struct RClass *scls, gc::Object *target, const gc::Variant **params, int count) {
    mrb_value obj;
    if (count) {
        mrb_value *argv = (mrb_value*)malloc(sizeof(mrb_value) * count);
        for (int i = 0; i < count; ++i) {
            argv[i] = ruby_h2r(mrb, *params[i]);
        }
        obj = mrb_obj_new(mrb, scls, count, argv);
        free(argv);
    }else {
        obj = mrb_obj_new(mrb, scls, 0, NULL);
    }
    
    mrb_define_class_method(mrb, scls, "native_class_call", &ruby_call_c, MRB_ARGS_REQ(2));
    
    RubyClass *mcls = (RubyClass*)makeClass();
    mcls->setNativeClass(target->getInstanceClass());
    mcls->setScript(this);
    mrb_obj_iv_set(mrb, (struct RObject *)scls, sym_native_class, mrb_cptr_value(mrb, mcls));
    
    RubyInstance *mins = (RubyInstance*)mcls->create(target);
    mins->script_class = scls;
    mins->setScriptInstance(mrb_obj_ptr(obj));
    mins->setSingleClass(true);
    
    struct RData* data = mrb_data_object_alloc(mrb, mrb->object_class, mins, ruby_type());
    mrb_iv_set(mrb, obj, sym_native_instance, mrb_obj_value(data));
    
    target->addScript(mins);
    return mins;
}

void RubyScript::defineFunction(const gc::StringName &name, const gc::Callback &function) {
    mrb_value val = ruby_h2r(mrb, function);
    string insname = "FUN_";
    insname += name.str();
    mrb_define_global_const(mrb, insname.c_str(), val);
    string script = "def ";
    script += name.str();
    script += " *argv;";
    script += insname;
    script += ".invoke argv;";
    script += "end";
    mrb_load_string(mrb, script.c_str());
    if (mrb->exc) {
        mrb_p(mrb, mrb_obj_value(mrb->exc));
        mrb->exc = NULL;
    }
}

gc::ScriptInstance *RubyClass::makeInstance() const {
    return new RubyInstance;
}

void RubyClass::bindScriptClass() {
    mrb_state *mrb = getRuby()->getMRB();
    struct RClass * rcls = (struct RClass *)getScriptClass();
    const gc::Class *hcls = getNativeClass();

    mrb_obj_iv_set(mrb, (struct RObject *)rcls, sym_native_class, mrb_cptr_value(mrb, this));
    mrb_define_method(mrb, rcls, "native_initialize", ruby_native_initialize, MRB_ARGS_ANY());
    mrb_define_method(mrb, rcls, "initialize", ruby_initialize, MRB_ARGS_ANY());
    const pointer_map &methods = hcls->getMethods();
    for (auto it = methods.begin(), _e = methods.end(); it != _e; ++it) {
        gc::StringName name(it->first);
        const gc::Method *method = (const gc::Method *)it->second;
        switch (method->getType()) {
            case gc::Method::Static:
            {
                mrb_define_class_method(mrb, rcls, name.str(), &ruby_call_class, MRB_ARGS_REQ(method->getParamsCount()));
            }
                break;

            default:
            {
                mrb_define_method(mrb, rcls, name.str(), &ruby_call_instance, MRB_ARGS_REQ(method->getParamsCount()));
            }
                break;
        }
    }
    const pointer_map &properties = hcls->getProperties();
    for (auto it = properties.begin(), _e = properties.end(); it != _e; ++it) {
        const gc::Property *property = (const gc::Property *)it->second;
        string name(property->getName().str());
        if (property->getGetter()) {
            mrb_define_method(mrb, rcls, name.c_str(), &ruby_get_instance, MRB_ARGS_NONE());
        }
        if (property->getSetter()) {
            name.push_back('=');
            mrb_define_method(mrb, rcls, name.c_str(), &ruby_set_instance, MRB_ARGS_REQ(1));
        }
    }
}

gc::Variant RubyClass::apply(const gc::StringName &name, const gc::Variant **params, int count) const {
    return ((RubyScript*)getScript())->_apply(mrb_obj_value(getScriptClass()), name, params, count);
}

gc::Variant RubyInstance::apply(const gc::StringName &name, const gc::Variant **params, int count) {
    return ((RubyScript*)getScript())->_apply(mrb_obj_value(getScriptInstance()), name, params, count);
}