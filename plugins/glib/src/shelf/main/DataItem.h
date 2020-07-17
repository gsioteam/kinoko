//
// Created by Gen2 on 2020-02-03.
//

#ifndef EV_DATAITEM_H
#define EV_DATAITEM_H

#include <core/Ref.h>
#include <core/Map.h>
#include "../models/BookData.h"
#include "../gs_define.h"

namespace gs {
    CLASS_BEGIN_N(DataItem, gc::Object)

        std::string title;
        std::string summary;
        std::string picture;
        std::string subtitle;
        std::string link;
        gc::Variant data;
        int type;

    public:

        static gc::Ref<DataItem> fromData(const gc::Ref<BookData> &data);

        static std::string toJSON(const gc::Array &arr);
        static gc::Array fromJSON(const std::string &j);

        METHOD const std::string &getTitle() const {
            return title;
        }
        METHOD void setTitle(const std::string &title) {
            this->title = title;
        }
        PROPERTY(title, getTitle, setTitle);

        METHOD const std::string &getSummary() const {
            return summary;
        }
        METHOD void setSummary(const std::string &summary) {
            this->summary = summary;
        }
        PROPERTY(summary, getSummary, setSummary);

        METHOD const std::string &getPicture() const {
            return picture;
        }
        METHOD void setPicture(const std::string &pic) {
            picture = pic;
        }
        PROPERTY(picture, getPicture, setPicture);

        METHOD const std::string &getSubtitle() const {
            return subtitle;
        }
        METHOD void setSubtitle(const std::string &subtitle) {
            this->subtitle = subtitle;
        }
        PROPERTY(subtitle, getSubtitle, setSubtitle);

        METHOD const std::string &getLink() const {
            return link;
        }
        METHOD void setLink(const std::string &link) {
            this->link = link;
        }
        PROPERTY(link, getLink, setLink);

        METHOD const gc::Variant &getData() {
            return data;
        }
        METHOD void setData(const gc::Variant &val) {
            this->data = val;
        }
        PROPERTY(data, getData, setData);

        METHOD int getType() const {
            return type;
        }
        METHOD void setType(int type) {
            this->type = type;
        }
        PROPERTY(type, getType, setType);

    protected:
        ON_LOADED_BEGIN(cls, gc::Object)
            ADD_PROPERTY(cls, "title", ADD_METHOD(cls, DataItem, getTitle), ADD_METHOD(cls, DataItem, setTitle));
            ADD_PROPERTY(cls, "summary", ADD_METHOD(cls, DataItem, getSummary), ADD_METHOD(cls, DataItem, setSummary));
            ADD_PROPERTY(cls, "picture", ADD_METHOD(cls, DataItem, getPicture), ADD_METHOD(cls, DataItem, setPicture));
            ADD_PROPERTY(cls, "subtitle", ADD_METHOD(cls, DataItem, getSubtitle), ADD_METHOD(cls, DataItem, setSubtitle));
            ADD_PROPERTY(cls, "link", ADD_METHOD(cls, DataItem, getLink), ADD_METHOD(cls, DataItem, setLink));
            ADD_PROPERTY(cls, "data", ADD_METHOD(cls, DataItem, getData), ADD_METHOD(cls, DataItem, setData));
            ADD_PROPERTY(cls, "type",ADD_METHOD(cls, DataItem, getType), ADD_METHOD(cls, DataItem, setType));
        ON_LOADED_END
    CLASS_END
}


#endif //EV_DATAITEM_H
