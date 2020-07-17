//
// Created by Gen2 on 2020-02-03.
//

#include "DataItem.h"
#include <nlohmann/json.hpp>
#include "../utils/JSON.h"

using namespace gs;
using namespace gc;

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
        item_json["title"] = item->getTitle();
        item_json["summary"] = item->getSummary();
        item_json["picture"] = item->getPicture();
        item_json["subtitle"] = item->getSubtitle();
        item_json["link"] = item->getLink();
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
        item->setTitle(val["title"]);
        item->setSummary(val["summary"]);
        item->setPicture(val["picture"]);
        item->setSubtitle(val["subtitle"]);
        item->setLink(val["link"]);
        item->setType(val["type"]);
        item->setData(JSON::parse(val["data"]));
        arr.push_back(item);
    }
    return arr;
}