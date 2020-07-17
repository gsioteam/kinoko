//
// Created by Gen2 on 2020-03-13.
//

#ifndef EV_MENU_H
#define EV_MENU_H

#include <core/Ref.h>
#include <core/Callback.h>
#include "../gs_define.h"

namespace gs {

    CLASS_BEGIN_N(MenuItem, gc::Object)

        std::string title;
        std::string id;
        gc::Callback on_change;
        gc::Variant value;
        gc::Variant default_value;

    protected:

        void change() {
            if (on_change) on_change(value);
        }

    public:

        METHOD const std::string &getTitle() const {
            return title;
        }
        METHOD void setTitle(const std::string &title) {
            this->title = title;
        }
        PROPERTY(title, getTitle, setTitle);

        METHOD const std::string &getId() const {
            return id;
        }
        METHOD void setId(const std::string &id) {
            this->id = id;
        }
        PROPERTY(id, getId, setId);

        METHOD const gc::Callback &getOnChange() const {
            return on_change;
        }
        METHOD void setOnChange(const gc::Callback &change) {
            on_change = change;
        }
        PROPERTY(on_change, getOnChange, setOnChange);

        METHOD const gc::Variant getValue() const {
            return value.empty() ? default_value : value;
        }
        METHOD void setValue(const gc::Variant &val) {
            value = val;
            change();
        }
        PROPERTY(value, getValue, setValue);

        METHOD const gc::Variant &getDefaultValue() const {
            return default_value;
        }
        METHOD void setDefaultValue(const gc::Variant &value) {
            default_value = value;
        }
        PROPERTY(default_value, getDefaultValue, setDefaultValue);


    protected:
        ON_LOADED_BEGIN(cls, gc::Object)
            ADD_PROPERTY(cls, "title", ADD_METHOD(cls, MenuItem, getTitle), ADD_METHOD(cls, MenuItem, setTitle));
            ADD_PROPERTY(cls, "id", ADD_METHOD(cls, MenuItem, getId), ADD_METHOD(cls, MenuItem, setId));
            ADD_PROPERTY(cls, "on_change", ADD_METHOD(cls, MenuItem, getOnChange), ADD_METHOD(cls, MenuItem, setOnChange));
            ADD_PROPERTY(cls, "value", ADD_METHOD(cls, MenuItem, getValue), ADD_METHOD(cls, MenuItem, setValue));
            ADD_PROPERTY(cls, "default_value", ADD_METHOD(cls, MenuItem, getDefaultValue), ADD_METHOD(cls, MenuItem, setDefaultValue));
        ON_LOADED_END
    CLASS_END

    CLASS_BEGIN_N(OptionsItem, MenuItem)
        gc::Array options;
    public:

        METHOD void setOptions(const gc::Array &options) {
            this->options = options;
        }
        METHOD const gc::Array &getOptions() const {
            return options;
        }
        PROPERTY(options, getOptions, setOptions);

    protected:
        ON_LOADED_BEGIN(cls, MenuItem)
            ADD_PROPERTY(cls, "options", ADD_METHOD(cls, OptionsItem, getOptions), ADD_METHOD(cls, OptionsItem, setOptions));
        ON_LOADED_END
    CLASS_END

    CLASS_BEGIN_N(CheckItem, MenuItem)
    CLASS_END

    CLASS_BEGIN_N(InputItem, MenuItem)
    CLASS_END

    CLASS_BEGIN_N(TitleItem, MenuItem)
    CLASS_END

    CLASS_BEGIN_N(ButtonItem, MenuItem)
    CLASS_END
}


#endif //EV_MENU_H
