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

bool Collection::reload() {
    if (loading) return false;
    Wk<Collection> weak = this;
    Variant var = C([=](Ref<Error> error, Array array){
        Ref<Collection> that = weak.lock();
        if (that) {
            that->trigger(NOTIFICATION_loading, false);
            if (error) {
                that->trigger(NOTIFICATION_error, error);
            } else {
                that->setData(array);
                that->loading = false;
                that->trigger(NOTIFICATION_dataChanged, array, DataReload);
            }
        }
    });
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
    Variant var = C([=](Ref<Error> error, Array array){
        Ref<Collection> that = weak.lock();
        if (that) {
            that->trigger(NOTIFICATION_loading, false);
            if (error) {
                that->trigger(NOTIFICATION_error, error);
            } else {
                for (int i = 0; i < array->size(); ++i) {
                    that->data->push_back(array->get(i));
                }
                that->loading = false;
                that->trigger(NOTIFICATION_dataChanged, array, DataAppend);
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