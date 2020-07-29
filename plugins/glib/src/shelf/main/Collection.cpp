//
// Created by gen on 2020/5/27.
//

#include "Collection.h"

using namespace gs;
using namespace gc;

DEVENT(Collection, reload);
DEVENT(Collection, loadMore);

DNOTIFICATION(Collection, dataChanged);
DNOTIFICATION(Collection, loading);
DNOTIFICATION(Collection, error);
DNOTIFICATION(Collection, reloadComplete);

bool Collection::reload() {
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
    LOG(i, "--- callEventReload");
    bool ret = apply(EVENT_reload, pointer_vector{&var});
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