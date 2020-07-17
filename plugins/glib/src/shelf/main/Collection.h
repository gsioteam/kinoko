//
// Created by gen on 2020/5/27.
//

#ifndef ANDROID_COLLECTION_H
#define ANDROID_COLLECTION_H

#include <core/Ref.h>
#include <core/Callback.h>
#include "../utils/Error.h"
#include "../gs_define.h"

namespace gs {

    ENUM_BEGIN(ChangeType)
        DataReload = 1,
        DataAppend = 2
    ENUM_END

    CLASS_BEGIN_N(Collection, gc::Object)

        bool loading = false;
        gc::Array data;
        std::string name = "default";

    public:

        Collection() {}

        EVENT(bool, reload, gc::Callback);
        EVENT(bool, loadMore, gc::Callback);

        NOTIFICATION(dataChanged, gc::Array array, ChangeType type);
        NOTIFICATION(loading, bool is_loading);
        NOTIFICATION(error, gc::Ref<Error>);

        METHOD bool reload();
        METHOD bool loadMore();

        METHOD const gc::Array &getData() const {
            return data;
        }
        METHOD void setData(const gc::Array &data) {
            this->data.vec() = data->vec();
        }
        PROPERTY(data, getData, setData);

        METHOD const std::string &getName() const {
            return name;
        }
        METHOD void setName(const std::string &name) {
            this->name = name;
        }
        PROPERTY(name, getName, setName);

        ON_LOADED_BEGIN(cls, gc::Object)
            ADD_METHOD(cls, Collection, reload);
            ADD_METHOD(cls, Collection, loadMore);
            ADD_PROPERTY(cls, "data", ADD_METHOD(cls, Collection, getData), ADD_METHOD(cls, Collection, setData));
            ADD_PROPERTY(cls, "name", ADD_METHOD(cls, Collection, getName), ADD_METHOD(cls, Collection, setName));
        ON_LOADED_END

    CLASS_END
}


#endif //ANDROID_COLLECTION_H
