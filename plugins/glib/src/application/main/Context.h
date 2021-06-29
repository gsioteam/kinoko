//
// Created by gen on 6/15/2020.
//

#ifndef ANDROID_CONTEXT_H
#define ANDROID_CONTEXT_H

#include <core/Ref.h>
#include <core/Map.h>
#include "./Collection.h"
#include "../gs_define.h"

namespace gs {
    class Settings;

    CLASS_BEGIN_NV(Context, gc::Object)
        static const std::string _null;

    public:

        enum ContextType {
            Project = 0,
            Data = 1,
            Search = 2,
            Setting = 3
        };

    protected:
        gc::Ref<Collection> target;
        gc::Callback on_data_changed;
        gc::Callback on_loading_status;
        gc::Callback on_error;
        gc::Callback on_reload_complete;
        gc::Callback on_call;
        std::string dir_path;
        ContextType type;
        bool first_enter = true;
        std::string project_key;
        std::shared_ptr<Settings> settings;

        void setupTarget(const gc::Ref<Collection> &target);
        void saveTime(const std::string &key);

        gc::Array load(bool &update, int &flag);
        void save(const gc::Array &arr);

        std::string readFile(const std::string &path) const;

    public:
//        ~Context();

        METHOD virtual void setup(const char *path, const gc::Variant &data) = 0;
        METHOD virtual bool isReady() {return !!target;}

        METHOD void reload(gc::Map data = gc::Map());
        METHOD void loadMore();

        METHOD void enterView();
        METHOD void exitView();

        METHOD void saveData();

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

        METHOD void setOnReloadComplete(const gc::Callback &callback) {
            on_reload_complete = callback;
        }
        PROPERTY(on_reload_complete, NULL, setOnReloadComplete);

        METHOD gc::Array getData() const {
            return target ? target->getData() : gc::Array();
        }
        PROPERTY(data, getData, NULL);

        METHOD void clearData();

        METHOD const gc::Variant &getInfoData() const {
            return target ? target->getInfoData() : gc::Variant::null();
        }
        METHOD void setInfoData(const gc::Variant &info_data) {
            if (target) target->setInfoData(info_data);
        }
        PROPERTY(info_data, getInfoData, setInfoData);

        METHOD const std::string &getProjectKey() const {
            return project_key;
        }
        PROPERTY(project_key, getProjectKey, NULL);

        static gc::Ref<Context> create(const std::string &path, const gc::Variant &data, ContextType type, const std::string &key, const std::shared_ptr<Settings> &settings);

        METHOD static gc::Array searchKeys(const std::string &key, int limit);
        METHOD static void removeSearchKey(const std::string &key);

        METHOD const gc::Variant &getSetting(const std::string &key) {
            return target->getSetting(key);
        }
        METHOD void setSetting(const std::string &key, const gc::Variant &value);

        METHOD std::string getTemp() const;
        PROPERTY(temp, getTemp, NULL);
        METHOD std::string getItemTemp() const;
        PROPERTY(item_temp, getItemTemp, NULL);

        METHOD gc::Variant applyFunction(const std::string &name, const gc::Array &args);

        METHOD void setOnCall(const gc::Callback &on_call) {
            this->on_call = on_call;
        }
        METHOD const gc::Callback &getOnCall() const {
            return on_call;
        }
        PROPERTY(on_call, getOnCall, setOnCall);

        ON_LOADED_BEGIN(cls, gc::Object)
            ADD_METHOD(cls, Context, setup);
            ADD_METHOD(cls, Context, isReady);
            ADD_METHOD(cls, Context, reload);
            ADD_METHOD(cls, Context, loadMore);
            ADD_METHOD(cls, Context, enterView);
            ADD_METHOD(cls, Context, exitView);
            ADD_METHOD(cls, Context, searchKeys);
            ADD_METHOD(cls, Context, removeSearchKey);
            ADD_METHOD(cls, Context, getSetting);
            ADD_METHOD(cls, Context, setSetting);
            ADD_METHOD(cls, Context, applyFunction);
            ADD_METHOD(cls, Context, clearData);
            ADD_METHOD(cls, Context, saveData);
            ADD_PROPERTY(cls, "on_data_changed", NULL, ADD_METHOD(cls, Context, setOnDataChanged));
            ADD_PROPERTY(cls, "on_loading_status", NULL, ADD_METHOD(cls, Context, setOnLoadingStatus));
            ADD_PROPERTY(cls, "on_error", NULL, ADD_METHOD(cls, Context, setOnError));
            ADD_PROPERTY(cls, "on_reload_complete", NULL, ADD_METHOD(cls, Context, setOnReloadComplete));
            ADD_PROPERTY(cls, "on_call", ADD_METHOD(cls, Context, getOnCall), ADD_METHOD(cls, Context, setOnCall));
            ADD_PROPERTY(cls, "data", ADD_METHOD(cls, Context, getData), NULL);
            ADD_PROPERTY(cls, "info_data", ADD_METHOD(cls, Context, getInfoData), ADD_METHOD(cls, Context, setInfoData));
            ADD_PROPERTY(cls, "project_key", ADD_METHOD(cls, Context, getProjectKey), NULL);
            ADD_PROPERTY(cls, "temp", ADD_METHOD(cls, Context, getTemp), NULL);
            ADD_PROPERTY(cls, "item_temp", ADD_METHOD(cls, Context, getItemTemp), NULL);
        ON_LOADED_END

    CLASS_END
}


#endif //ANDROID_CONTEXT_H
