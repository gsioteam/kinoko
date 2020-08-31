//
// Created by gen on 6/15/2020.
//

#include "Context.h"

#ifdef __APPLE__
#include <script/js_core/JSCoreScript.h>
#endif
#ifdef __ANDROID__
#include <script/v8/V8Script.h>
#endif

#include <script/ruby/RubyScript.h>
#include "../utils/SharedData.h"
#include <core/Callback.h>
#include "../models/KeyValue.h"
#include "../models/BookData.h"
#include "DataItem.h"
#include "../models/SearchData.h"
#include "Settings.h"
#include <sys/time.h>

#include "../gs_define.h"

using namespace gs;
using namespace gscript;
using namespace std;
using namespace gc;

namespace gs {
    const std::string Context::_null;
    StringName KeepKey = "_keep";

#ifdef __APPLE__

    CLASS_BEGIN_N(JavaScriptContext, Context)

        JSCoreScript *script;

    public:
        static bool isSupport(const std::string &ext) {
            return ext == "js";
        }

        JavaScriptContext() {
            string v8_root = shared::repo_path() + "/env/v8";
            script = new JSCoreScript(v8_root.c_str());
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
                    target->setSettings(settings);
                    target->apply(KeepKey);
                    setupTarget(target);
                } else {
                    LOG(w, "Failed to load script (%s)", path);
                }
            }
        }

    CLASS_END

#endif

#ifdef __ANDROID__
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
                    target->setSettings(settings);
                    target->apply(KeepKey);
                    setupTarget(target);
                } else {
                    LOG(w, "Failed to load script (%s)", path);
                }
            }
        }

    CLASS_END
#endif
    

    CLASS_BEGIN_N(RubyContext, Context)

        RubyScript *script;

    public:
        static bool isSupport(const std::string &ext) {
            return ext == "rb" || ext == "mrb";
        }

        void setup(const char *path, const gc::Variant &data) override{
            script->runFile(path);
            Variant var = script->runScript("$exports");
            if (var.getTypeClass()->isTypeOf(gc::_Callback::getClass())) {
                gc::Callback func = var;
                Variant tar = func(data);
                if (tar && tar.getTypeClass()->isTypeOf(Collection::getClass())) {
                    target = tar;
                    target->setSettings(settings);
                    target->apply(KeepKey);
                    setupTarget(target);
                } else {
                    LOG(w, "Failed to load script (%s)", path);
                }
            }
        }

        RubyContext() {
            script = new RubyScript();
            string rb_root = shared::repo_path() + "/env/ruby";
            script->setup(rb_root.c_str());
        }
        ~RubyContext() {
            delete script;
        }

    CLASS_END

    int64_t currentTime() {
        struct timeval s_time;
        gettimeofday(&s_time, NULL);
        return s_time.tv_sec * 1000 + s_time.tv_usec / 1000;
    }
}

gc::Ref<Context> Context::create(const std::string &path, const Variant &data, ContextType type, const std::string &key, const std::shared_ptr<Settings> &settings) {
    size_t idx = path.find_last_of('.');
    if (idx < path.size()) {
        std::string ext = path.substr(idx+1);
        if (JavaScriptContext::isSupport(ext)) {
            JavaScriptContext *ctx = new JavaScriptContext;
            ctx->type = type;
            ctx->project_key = key;
            ctx->settings = settings;
            ctx->dir_path = path.substr(0, idx);
            ctx->setup(path.c_str(), data);
            return ctx;
        } else if (RubyContext::isSupport(ext)) {
            RubyContext *ctx = new RubyContext;
            ctx->type = type;
            ctx->project_key = key;
            ctx->settings = settings;
            ctx->dir_path = path.substr(0, idx);
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
        } else if (type != Search) {
            if (update || !data->size()) {
                reload();
            }
        }
    }
}

void Context::exitView() {
    if (!isReady()) return;
    if (type == Setting) {
        Array arr = getData();
        for (auto it = arr->begin(), _e = arr->end(); it != _e; ++it) {
            Ref<SettingItem> item = *it;
            if (item->getDefaultValue().getType() != Variant::TypeNull &&
            settings->get(item->getName()).getType() == Variant::TypeNull) {
                settings->set(item->getName(), item->getDefaultValue());
            }
        }
        settings->save();
    }
}

void Context::reload(gc::Map data) {
    if (!isReady()) return;
    if (!data) data = Map();
    target->reload(data);
    if (type == Search) {
        Variant key = data->get("key");
        if (key) {
            SearchData::insert(key, currentTime());
        }
    }
}

void Context::loadMore() {
    if (!isReady()) return;
    target->loadMore();
}

void Context::setupTarget(const gc::Ref<Collection> &target) {
    Wk<Context> weak = this;
    target->on(Collection::NOTIFICATION_dataChanged, C([=](Collection::ChangeType type, Array array, int idx){
        Ref<Context> that = weak.lock();
        if (that) {
            for (auto it = array->begin(), _e = array->end(); it != _e; ++it) {
                if ((*it).getTypeClass()->isTypeOf(DataItem::getClass())) {
                    Ref<DataItem> item = *it;
                    item->setProjectKey(project_key);
                }
            }
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
            switch (that->type) {
                case Context::Chapter: {
                    Ref<DataItem> item = this->getInfoData();
                    if (item) {
                        Ref<BookData> data = item->saveData(false);
                        if (data) {
                            data->setFlag(1);
                            data->save();
                        }
                    }
                    break;
                }
            }
            if (that->on_reload_complete) {
                that->on_reload_complete();
            }
        }
    }));
}

gc::Array Context::searchKeys(const std::string &key, int limit) {
    Ref<Query> query = SearchData::query();
    query->setSortAsc(false);
    ref_vector keys;
    if (key.empty()) {
        keys = query->sortBy("date")->limit(limit)->res();
    } else {
        keys = query->like("key", "%"+key+"%")->sortBy("date")->limit(limit)->res();
        if (keys.size() < limit) {
            int over = limit - keys.size();
            Ref<Query> query = SearchData::query();
            query->setSortAsc(false);
            ref_vector ex_keys = query->sortBy("date")->limit(limit)->res();
            for (auto it = ex_keys.begin(), _e = ex_keys.end(); it != _e; ++it) {
                Ref<SearchData> data = *it;
                int id = data->getIdentifier();
                bool not_exist = true;
                {
                    for (auto it = keys.begin(), _e = keys.end(); it != _e; ++it) {
                        Ref<SearchData> data = *it;
                        if (data->getIdentifier() == id) {
                            not_exist = false;
                            break;
                        }
                    }
                }
                if (not_exist) {
                    keys.push_back(data);
                    over--;
                    if (over <= 0) {
                        break;
                    }
                }
            }
        }
    }

    gc::Array res;
    for (auto it = keys.begin(), _e = keys.end(); it != _e; ++it) {
        Ref<SearchData> data = *it;
        res.push_back(data->getKey());
    }
    return res;
}

void Context::removeSearchKey(const std::string &key) {
    ref_vector res = SearchData::query()->equal("key", key)->res();
    if (res.size()) {
        for (auto it = res.begin(), _e = res.end(); it != _e; ++it) {
            Ref<SearchData> data = *it;
            data->remove();
        }
    }
}

std::string Context::getTemp() const {
    if (target) {
        std::string temp = target->getTemp();
        if (!temp.empty()) {

        }
    }
    return _null;
}
