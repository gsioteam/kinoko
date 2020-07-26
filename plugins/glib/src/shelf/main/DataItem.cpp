//
// Created by Gen2 on 2020-02-03.
//

#include "DataItem.h"
#include <nlohmann/json.hpp>
#include "../utils/JSON.h"
#include "../models/CollectionData.h"

using namespace gs;
using namespace gc;
using namespace std;

gc::Ref<DataItem> DataItem::fromData(const gc::Ref<BookData> &data) {
    Ref<DataItem> item(new_t(DataItem));
    if (data) {
        item->setTitle(data->getTitle());
        item->setSubtitle(data->getSubtitle());
        item->setSummary(data->getSummary());
        item->setPicture(data->getPicture());
        item->setLink(data->getLink());
        item->setType(data->getType());
        item->setData(data->getData());
        item->setProjectKey(data->getProjectKey());
    }
    return item;
}

std::string DataItem::toJSON(const gc::Array &arr) {
    nlohmann::json json = nlohmann::json::array();
    for (auto it = arr->begin(), _e = arr->end(); it != _e; ++it) {
        Ref<DataItem> item = *it;
        nlohmann::json item_json = nlohmann::json::object();
#define GET(K, M) { \
        string str = item->M(); \
        if (!str.empty()) item_json[K] = str; \
        }
        GET("title", getTitle);
        GET("summary", getSummary);
        GET("picture", getPicture);
        GET("subtitle", getSubtitle);
        GET("link", getLink);
//        GET("project_key", getProjectKey);
        item_json["type"] = item->getType();
        if (item->data) {
            item_json["data"] = JSON::serialize(item->data);
        }
        json.push_back(item_json);
    }
    return json.dump();
}

gc::Array DataItem::fromJSON(const std::string &json) {
    Array arr;
    if (json.empty()) return arr;
    nlohmann::json jarr = nlohmann::json::parse(json);
    if (!jarr.is_array()) return arr;
    for (auto it = jarr.begin(), _e = jarr.end(); it != _e; ++it) {
        auto &val = it.value();
        Ref<DataItem> item(new DataItem());

#define SET(K, M) { \
            auto it = val.find(K); \
            if (it != val.end()) item->M(it.value()); \
        }
        SET("title", setTitle);
        SET("summary", setSummary);
        SET("picture", setPicture);
        SET("subtitle", setSubtitle);
        SET("link", setLink);
//        SET("project_key", setProjectKey);
        item->setType(val["type"]);
        if (val.contains("data")) {
            item->setData(JSON::parse(val["data"]));
        }
        arr.push_back(item);
    }
    return arr;
}

void DataItem::fill(const gc::Ref<BookData> &data) {
    setTitle(data->getTitle());
    setSummary(data->getSummary());
    setPicture(data->getPicture());
    setSubtitle(data->getSubtitle());
    setLink(data->getLink());
    setType(data->getType());
    setProjectKey(data->getProjectKey());
    const std::string &dstr = data->getData();
    if (dstr.empty()) {
        setData(Variant::null());
    } else {
        setData(JSON::parse(dstr));
    }
}

gc::Ref<BookData> DataItem::saveData(bool save) {
    Array arr = BookData::query()->equal("link", getLink())->andQ()->equal("project_key", project_key)->results();
    if (save) {
        Ref<BookData> data = arr->size() ? (Ref<BookData>)arr->get(0) : Ref<BookData>(new BookData());
        data->setTitle(getTitle());
        data->setSummary(getSummary());
        data->setPicture(getPicture());
        data->setSubtitle(getSubtitle());
        data->setLink(getLink());
        data->setType(getType());
        if (getData()) {
            data->setData(JSON::serialize(getData()).dump());
        } else {
            data->setData("");
        }
        data->setProjectKey(getProjectKey());
        return data;
    } else {
        return arr->size() ? (Ref<BookData>)arr->get(0) : Ref<BookData>::null();
    }
}

void DataItem::saveToCollection(const std::string &type, int flag) {
    Ref<BookData> data = saveData(false);
    if (data) {
        Ref<CollectionData> col = CollectionData::find(type, data->getIdentifier());
        if (!col) {
            col = new CollectionData;
            col->setType(type);
            col->setTargetID(data->getIdentifier());
        }
        col->setFlag(flag);
        col->save();
    }else {
        LOG(e, "Can not save to collection %s, data not found.", type.c_str());
    }
}

gc::Array DataItem::loadCollectionItems(const std::string &type) {
    Array cols = CollectionData::all(type);
    Array keys;
    for (auto it = cols->begin(), _e = cols->end(); it != _e; ++it) {
        Ref<CollectionData> col = *it;
        keys.push_back(col->getTargetID());
    }
    Array result;
    Array res = BookData::query()->in("identifier", keys)->results();
    for (auto it = res->begin(), _e = res->end(); it != _e; ++it) {
        result.push_back(DataItem::fromData(*it));
    }
    return result;
}

bool DataItem::isInCollection(const std::string &type) {
    Ref<BookData> data = saveData(false);
    if (data) {
        Ref<CollectionData> col = CollectionData::find(type, data->getIdentifier());
        return col;
    }
    return false;
}

void DataItem::removeFromCollection(const std::string &type) {
    Ref<BookData> data = saveData(false);
    if (data) {
        Ref<CollectionData> col = CollectionData::find(type, data->getIdentifier());
        if (col) col->remove();
    }
}

gc::Ref<DataItem> DataItem::fromCollectionData(const gc::Ref<CollectionData> &data) {
    Array arr = BookData::query()->equal("identifier", data->getTargetID())->results();
    if (arr->size()) {
        return DataItem::fromData(arr->get(0));
    }
    return gc::Ref<DataItem>::null();
}