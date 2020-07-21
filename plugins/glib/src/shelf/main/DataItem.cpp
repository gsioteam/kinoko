//
// Created by Gen2 on 2020-02-03.
//

#include "DataItem.h"
#include <nlohmann/json.hpp>
#include "../utils/JSON.h"

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
        item_json["type"] = item->getType();
        item_json["data"] = JSON::serialize(item->data);
        json.push_back(item_json);
    }
    return json.dump();
}

gc::Array DataItem::fromJSON(const std::string &json) {
    nlohmann::json jarr = nlohmann::json::parse(json);
    Array arr;
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
        item->setType(val["type"]);
        item->setData(JSON::parse(val["data"]));
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
    setData(JSON::parse(data->getData()));
}

gc::Ref<BookData> DataItem::saveData(bool save, const std::string &hash) {
    Array arr = BookData::query()->equal("link", getLink())->andQ()->equal("hash", hash)->results();
    if (save) {
        Ref<BookData> data = arr->size() ? (Ref<BookData>)arr->get(0) : Ref<BookData>(new BookData());
        data->setTitle(getTitle());
        data->setSummary(getSummary());
        data->setPicture(getPicture());
        data->setSubtitle(getSubtitle());
        data->setLink(getLink());
        data->setType(getType());
        data->setData(JSON::serialize(getData()).dump());
        data->setHash(hash);
        return data;
    } else {
        return arr->size() ? (Ref<BookData>)arr->get(0) : Ref<BookData>::null();
    }
}