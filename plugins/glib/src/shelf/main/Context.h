//
// Created by gen on 6/15/2020.
//

#ifndef ANDROID_CONTEXT_H
#define ANDROID_CONTEXT_H

#include <core/Ref.h>
#include "./Collection.h"
#include "../gs_define.h"

namespace gs {

    CLASS_BEGIN_NV(Context, gc::Object)

    public:

        ENUM_BEGIN(ContextType)
            Project = 0,
            Book = 1,
            Chapter = 2,
        ENUM_END

    protected:
        gc::Ref<Collection> target;
        gc::Callback on_data_changed;
        gc::Callback on_loading_status;
        gc::Callback on_error;
        ContextType type;
        bool first_enter = true;
        std::string key;

        void setupTarget(const gc::Ref<Collection> &target);
        void saveTime(const std::string &key);

        gc::Array load(bool &update, int &flag);
        void save(const gc::Array &arr);

    public:
//        ~Context();

        METHOD virtual void setup(const char *path, const gc::Variant &data) = 0;
        METHOD virtual bool isReady() {return !!target;}

        METHOD void reload();
        METHOD void loadMore();

        METHOD void enterView();
        METHOD void exitView();

        METHOD void setOnDataChanged(const gc::Callback &callback) {
            on_data_changed = callback;
        }
        PROPERTY(on_data_changed, NULL, setOnDataChange);
        METHOD void setOnLoadingStatus(const gc::Callback &callback) {
            on_loading_status = callback;
        }
        PROPERTY(on_loading_status, NULL, setOnLoadingStatus);
        METHOD void setOnError(const gc::Callback &callback) {
            on_error = callback;
        }
        PROPERTY(on_error, NULL, setOnError);

        METHOD gc::Array getData() const {
            return target ? target->getData() : gc::Array();
        }
        PROPERTY(data, getData, NULL);

        METHOD const gc::Variant &getInfoData() const {
            return target->getInfoData();
        }
        METHOD void setInfoData(const gc::Variant &info_data) {
            target->setInfoData(info_data);
        }
        PROPERTY(info_data, getInfoData, setInfoData);

        static gc::Ref<Context> create(const std::string &path, const gc::Variant &data, ContextType type, const std::string &key);

        ON_LOADED_BEGIN(cls, gc::Object)
            ADD_METHOD(cls, Context, setup);
            ADD_METHOD(cls, Context, isReady);
            ADD_METHOD(cls, Context, reload);
            ADD_METHOD(cls, Context, loadMore);
            ADD_METHOD(cls, Context, enterView);
            ADD_METHOD(cls, Context, exitView);
            ADD_PROPERTY(cls, "on_data_changed", NULL, ADD_METHOD(cls, Context, setOnDataChanged));
            ADD_PROPERTY(cls, "on_loading_status", NULL, ADD_METHOD(cls, Context, setOnLoadingStatus));
            ADD_PROPERTY(cls, "on_error", NULL, ADD_METHOD(cls, Context, setOnError));
            ADD_PROPERTY(cls, "data", ADD_METHOD(cls, Context, getData), NULL);
            ADD_PROPERTY(cls, "info_data", ADD_METHOD(cls, Context, getInfoData), ADD_METHOD(cls, Context, setInfoData));
        ON_LOADED_END

    CLASS_END
}


#endif //ANDROID_CONTEXT_H
