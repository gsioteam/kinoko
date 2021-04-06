//
// Created by gen on 2020/5/27.
//

#include "Collection.h"
#include "Settings.h"
#include "../utils/Platform.h"

using namespace gs;
using namespace gc;

DEVENT(Collection, reload);
DEVENT(Collection, loadMore);

DNOTIFICATION(Collection, dataChanged);
DNOTIFICATION(Collection, loading);
DNOTIFICATION(Collection, error);
DNOTIFICATION(Collection, reloadComplete);

bool Collection::reload(const gc::Map &data) {
    if (loading) return false;
    Wk<Collection> weak = this;
    Variant var = C([=](Ref<Error> error){
        Ref<Collection> that = weak.lock();
        if (that) {
            that->loading = false;
            that->trigger(NOTIFICATION_loading, false);
            if (error) {
                that->trigger(NOTIFICATION_error, error);
            } else {
                that->trigger(NOTIFICATION_reloadComplete);
            }
        }
    });
    bool ret = applyArgv(EVENT_reload, data, var);
    if (ret) {
        loading = true;
        trigger(NOTIFICATION_loading, true);
    }
    return ret;
}

bool Collection::loadMore() {
    if (loading) return false;
    Wk<Collection> weak = this;
    Variant var = C([=](Ref<Error> error){
        Ref<Collection> that = weak.lock();
        if (that) {
            that->loading = false;
            that->trigger(NOTIFICATION_loading, false);
            if (error) {
                that->trigger(NOTIFICATION_error, error);
            }
        }
    });
    bool ret = apply(EVENT_loadMore, pointer_vector{&var});
    if (ret) {
        loading = true;
        trigger(NOTIFICATION_loading, true);
    }
    return ret;
}

void Collection::initialize(gc::Variant info_data) {
    this->info_data = info_data;
}

void Collection::setDataAt(const gc::Variant &var, int idx) {
    if (data->size() <= idx) {
        data->resize(idx + 1);
    }
    data->set(idx, var);

    trigger(NOTIFICATION_dataChanged, Changed, Array(var), idx);
}

void Collection::setData(const gc::Array &array) {
    data->vec() = array->vec();
    trigger(NOTIFICATION_dataChanged, Reload, array);
}

void Collection::appendData(const gc::Array &array) {
    long o_size = data->size();
    for (int i = 0; i < array->size(); ++i) {
        data->push_back(array->get(i));
    }
    trigger(NOTIFICATION_dataChanged, Reload, array, o_size);
}

const gc::Variant & Collection::getSetting(const std::string &key) {
    return settings ? settings->get(key) : Variant::null();
}

void Collection::setSetting(const std::string &key, const gc::Variant &value) {
    if (settings) settings->set(key, value);
}

void Collection::synchronizeSettings() {
    if (settings) settings->save();
}

gc::Variant Collection::call(const std::string &name, const gc::Array &args) {
    if (on_call) {
        return on_call(name, args);
    }
    return Variant::null();
}

std::string Collection::getLanguage() {
    return Platform::getLanguage();
}