//
// Created by gen on 6/15/2020.
//

#include "Context.h"
#include <script/v8/V8Script.h>
#include <script/ruby/RubyScript.h>
#include "../utils/SharedData.h"
#include <core/Callback.h>
#include "../models/KeyValue.h"
#include "../models/BookData.h"
#include "DataItem.h"

#include "../gs_define.h"

using namespace gs;
using namespace gscript;
using namespace std;
using namespace gc;

namespace gs {
    StringName KeepKey = "_keep";

    CLASS_BEGIN_N(JavaScriptContext, Context)

        V8Script *script;

    public:
        static bool isSupport(const std::string &ext) {
            return ext == "js";
        }

        JavaScriptContext() {
            string v8_root = shared::repo_path() + "/env/v8";
            script = new V8Script(v8_root.c_str());
        }

        ~JavaScriptContext() {
            delete script;
        }

        void setup(const char *path, const gc::Variant &data) override {
//            string target_path = shared::repo_path() + "/" + path;
            Variant var = script->runFile(path);
            if (var.getTypeClass()->isTypeOf(gc::_Callback::getClass())) {
                gc::Callback func = var;
                Variant tar = func(data);
                if (tar && tar.getTypeClass()->isTypeOf(Collection::getClass())) {
                    target = tar;
                    target->apply(KeepKey);
                    setupTarget(target);
                } else {
                    LOG(w, "Failed to load script (%s)", path);
                }
            }
        }

    CLASS_END

    CLASS_BEGIN_N(RubyContext, Context)

        RubyScript *script;

    public:
        static bool isSupport(const std::string &ext) {
            return ext == "rb" || ext == "mrb";
        }

        void setup(const char *path, const gc::Variant &data) override{
            script = new RubyScript();
        }

    CLASS_END
}

gc::Ref<Context> Context::create(const std::string &path, const Variant &data) {
    size_t idx = path.find_last_of('.');
    if (idx < path.size()) {
        std::string ext = path.substr(idx+1);
        if (JavaScriptContext::isSupport(ext)) {
            JavaScriptContext *ctx = new JavaScriptContext;
            ctx->setup(path.c_str(), data);
            return ctx;
        } else if (RubyContext::isSupport(ext)) {
            RubyContext *ctx = new RubyContext;
            ctx->setup(path.c_str(), data);
            return ctx;
        }
    }
    return nullptr;
}

void Context::enterView() {
    if (!isReady()) return;
    string list = KeyValue::get(shared::HOME_PAGE_LIST + target->getName());
    if (list.empty()) {
        reload();
    } else {
        Array data = BookData::query()->in("identifier", list)->results();
        Array items;
        for (auto it = data->begin(), _e = data->end(); it != _e ; ++it) {
            items->push_back(DataItem::fromData(*it));
        }
        target->setData(items);
        if (this->on_data_changed) {
            this->on_data_changed(items, DataReload);
        }
    }
}

void Context::exitView() {
    if (!isReady()) return;
}

void Context::reload() {
    if (!isReady()) return;
    target->reload();
}

void Context::loadMore() {
    if (!isReady()) return;
}

void Context::setupTarget(const gc::Ref<Collection> &target) {
    Wk<Context> weak = this;
    target->on(Collection::NOTIFICATION_dataChanged, C([=](Array array, ChangeType type){
        Ref<Context> that = weak.lock();
        if (that && that->on_data_changed) {
            that->on_data_changed(array, type);
        }
    }));
    target->on(Collection::NOTIFICATION_loading, C([=](bool is_loading) {
        Ref<Context> that = weak.lock();
        if (that && that->on_loading_status) {
            that->on_loading_status(is_loading);
        }
    }));
    target->on(Collection::NOTIFICATION_error, C([=](Ref<Error> error) {
        Ref<Context> that = weak.lock();
        if (that && that->on_error) {
            that->on_error(error);
        }
    }));
}