//
// Created by gen on 8/17/20.
//

#ifndef KINOKO_GIT_SETTINGSCONTEXT_H
#define KINOKO_GIT_SETTINGSCONTEXT_H

#include <core/Ref.h>
#include <core/Callback.h>
#include <core/Map.h>
#include "../gs_define.h"

namespace gs {
    ENUM_BEGIN(SettingType)
        SettingHeader = 0,
        SettingSwitch,
        SettingInput,
        SettingOptions
    ENUM_END

    class Settings {

        std::string project_key;
        bool init = false;
        gc::Map map;

    public:

        Settings(const std::string &key) : project_key(key) {}

        bool exist() const;

        void load();
        const gc::Variant &get(const std::string &key);
        void set(const std::string &key, const gc::Variant &value);

        void save();

    };

    CLASS_BEGIN_N(SettingItem, gc::Object)
        SettingType type;
        std::string title;
        std::string name;
        gc::Variant default_value;
        gc::Variant data;

    public:

        METHOD SettingType getType() const { return type; }
        METHOD void setType(SettingType type) { this->type = type; }
        PROPERTY(type, getType, setType)

        METHOD const std::string &getTitle() const { return title; }
        METHOD void setTitle(const std::string &title) { this->title = title; }
        PROPERTY(title, getTitle, setTitle)

        METHOD const std::string &getName() const { return name; }
        METHOD void setName(const std::string &name) {this->name = name;}
        PROPERTY(name, getName, setName)

        METHOD const gc::Variant &getDefaultValue() const {return default_value;}
        METHOD void setDefaultValue(const gc::Variant &value) {this->default_value = value;}
        PROPERTY(default_value, getDefaultValue, setDefaultValue)

        METHOD const gc::Variant &getData() const { return data; }
        METHOD void setData(const gc::Variant &data) {this->data = data;}
        PROPERTY(data, getData, setData)

        METHOD void initialize(
                SettingType type,
                const std::string &name,
                const std::string &title,
                const gc::Variant &default_value,
                const gc::Variant &data
        );

        ON_LOADED_BEGIN(cls, gc::Object)
            ADD_PROPERTY_EX(cls, "type", SettingItem, getType, setType);
            ADD_PROPERTY_EX(cls, "title", SettingItem, getTitle, setTitle);
            ADD_PROPERTY_EX(cls, "name", SettingItem, getName, setName);
            ADD_PROPERTY_EX(cls, "default_value", SettingItem, getDefaultValue, setDefaultValue);
            ADD_PROPERTY_EX(cls, "data", SettingItem, getData, setData);

            ADD_METHOD_D(cls, SettingItem, initialize, gc::Variant::null(), gc::Variant::null());
        ON_LOADED_END

    CLASS_END
}

#endif //KINOKO_GIT_SETTINGSCONTEXT_H
