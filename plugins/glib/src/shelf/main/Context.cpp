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
#include <sys/time.h>

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

    int64_t currentTime() {
        struct timeval s_time;
        gettimeofday(&s_time, NULL);
        return s_time.tv_sec * 1000 + s_time.tv_usec / 1000;
    }
}

gc::Ref<Context> Context::create(const std::string &path, const Variant &data, ContextType type, const std::string &key) {
    size_t idx = path.find_last_of('.');
    if (idx < path.size()) {
        std::string ext = path.substr(idx+1);
        if (JavaScriptContext::isSupport(ext)) {
            JavaScriptContext *ctx = new JavaScriptContext;
            ctx->type = type;
            ctx->project_key = key;
            ctx->setup(path.c_str(), data);
            return ctx;
        } else if (RubyContext::isSupport(ext)) {
            RubyContext *ctx = new RubyContext;
            ctx->type = type;
            ctx->project_key = key;
            ctx->setup(path.c_str(), data);
            return ctx;
        }
    }
    return nullptr;
}

#define TIME_TAIL "-time"
#define EXPIRE_TIME (30 * 60 * 100)

void Context::saveTime(const std::string &key) {
    char time_str[256];
    sprintf(time_str, "%lld", currentTime());
    KeyValue::set(key + TIME_TAIL, time_str);
}

gc::Array Context::load(bool &update, int &flag) {
    switch (type) {
        case Project: {
            Map data = target->getInfoData();
            std::string url = data["url"];
            string save_key = project_key + ":" + url;
            string list = KeyValue::get(save_key);
            string timestr = KeyValue::get(save_key + TIME_TAIL);
            long long time = timestr.empty() ? 0 : atoll(timestr.c_str());
            update = (currentTime() - time) > EXPIRE_TIME;
            if (!list.empty()) {
                return DataItem::fromJSON(list);
            }
            break;
        }
        case Book: {
            Ref<DataItem> item = this->getInfoData();
            if (item) {
                item->setProjectKey(project_key);
                Ref<BookData> data = item->saveData(false);
                if (data) {
                    flag = data->getFlag();
                    item->fill(data);
                    update = (currentTime() - data->getDate()) > EXPIRE_TIME;
                    return DataItem::fromJSON(data->getSubItems());
                } else {
                    Ref<BookData> data = item->saveData(true);
                    data->save();
                }
            }
            break;
        }
        case Chapter: {
            Ref<DataItem> item = this->getInfoData();
            if (item) {
                item->setProjectKey(project_key);
                Ref<BookData> data = item->saveData(false);
                if (data) {
                    flag = data->getFlag();
                    item->fill(data);
                    update = (currentTime() - data->getDate()) > EXPIRE_TIME;
                    return DataItem::fromJSON(data->getSubItems());
                } else {
                    Ref<BookData> data = item->saveData(true);
                    data->save();
                }
            }
            break;
        }
    }
    return gc::Array();
}

void Context::save(const gc::Array &arr) {
    switch (type) {
        case Project: {
            Map data = target->getInfoData();
            std::string url = data["url"];
            string save_key = project_key + ":" + url;
            KeyValue::set(save_key, DataItem::toJSON(arr));
            saveTime(save_key);
            break;
        }
        case Book: {
            Ref<DataItem> item = this->getInfoData();
            if (item) {
                Ref<BookData> data = item->saveData(true);
                data->setSubItems(DataItem::toJSON(arr));
                data->setDate(currentTime());
                data->save();
            }
            break;
        }
        case Chapter: {
            Ref<DataItem> item = this->getInfoData();
            if (item) {
                Ref<BookData> data = item->saveData(true);
                data->setSubItems(DataItem::toJSON(arr));
                data->setDate(currentTime());
                data->save();
            }
            break;
        }
    }
}

//Context::~Context() {}

void Context::enterView() {
    if (!isReady()) return;
    if (first_enter) {
        first_enter = false;
        bool update = false;
        int flag = 0;
        Array data = load(update, flag);
        if (data.size()) {
            target->setData(data);
            if (this->on_data_changed) {
                this->on_data_changed(Collection::Reload, data, 0);
            }
        }
        if (type == Chapter) {
            if (flag == 0) {
                reload();
            }
        } else {
            if (update || !data->size()) {
                reload();
            }
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
    target->on(Collection::NOTIFICATION_dataChanged, C([=](Collection::ChangeType type, Array array, int idx){
        Ref<Context> that = weak.lock();
        if (that) {
            if (type != Collection::Append && that->getData()->size() > 0) {
                save(that->getData());
            }
            if (that->on_data_changed) {
                that->on_data_changed(type, array, idx);
            }
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
    target->on(Collection::NOTIFICATION_reloadComplete, C([=]() {
        Ref<Context> that = weak.lock();
        if (that) {
            if (that->type == Context::Chapter) {
                Ref<DataItem> item = this->getInfoData();
                if (item) {
                    Ref<BookData> data = item->saveData(false);
                    if (data) {
                        data->setFlag(1);
                        data->save();
                    }
                }
            }
            if (that->on_reload_complete) {
                that->on_reload_complete();
            }
        }
    }));
}