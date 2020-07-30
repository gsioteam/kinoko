//
// Created by gen on 2020/5/27.
//

#ifndef ANDROID_COLLECTION_H
#define ANDROID_COLLECTION_H

#include <core/Ref.h>
#include <core/Map.h>
#include <core/Callback.h>
#include "../utils/Error.h"
#include "../gs_define.h"

namespace gs {

    CLASS_BEGIN_N(Collection, gc::Object)

        bool loading = false;
        gc::Array data;
        gc::Variant info_data;

    public:

        ENUM_BEGIN(ChangeType)
            Reload = 1,
            Append = 2,
            Changed = 3
        ENUM_END

        Collection() {}

        METHOD void initialize(gc::Variant info_data);

        EVENT(bool, reload, gc::Map, gc::Callback);
        EVENT(bool, loadMore, gc::Callback);

        NOTIFICATION(dataChanged, ChangeType type, gc::Array array, int index);
        NOTIFICATION(loading, bool is_loading);
        NOTIFICATION(error, gc::Ref<Error>);
        NOTIFICATION(reloadComplete);

        METHOD bool reload(const gc::Map &data);
        METHOD bool loadMore();

        METHOD void setDataAt(const gc::Variant &var, int idx);
        METHOD void setData(const gc::Array &array);
        METHOD void appendData(const gc::Array &array);

        METHOD const gc::Array &getData() const {
            return data;
        }
        PROPERTY(data, getData, setData);

        METHOD const gc::Variant &getInfoData() const {
            return info_data;
        }
        METHOD void setInfoData(const gc::Variant &info_data) {
            this->info_data = info_data;
        }
        PROPERTY(info_data, getInfoData, setInfoData);

        ON_LOADED_BEGIN(cls, gc::Object)
            INITIALIZER(cls, Collection, initialize);
            ADD_METHOD(cls, Collection, reload);
            ADD_METHOD(cls, Collection, loadMore);
            ADD_METHOD(cls, Collection, setDataAt);
            ADD_METHOD(cls, Collection, appendData);
            ADD_PROPERTY(cls, "data", ADD_METHOD(cls, Collection, getData), ADD_METHOD(cls, Collection, setData));
            ADD_PROPERTY(cls, "info_data", ADD_METHOD(cls, Collection, getInfoData), ADD_METHOD(cls, Collection, setInfoData));
        ON_LOADED_END

    CLASS_END
}


#endif //ANDROID_COLLECTION_H
