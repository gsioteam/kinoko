//
// Created by gen on 7/24/20.
//

#include <nlohmann/json.hpp>
#include "CollectionData.h"
#include "../utils/JSON.h"

using namespace gs;

CollectionData::CollectionData() : flag(0) {
}

gc::Array CollectionData::all(const std::string &type) {
    return CollectionData::query()->equal("type", type)->sortBy("identifier")->results();
}

gc::Array CollectionData::findBy(const std::string &type, const std::string &sort, int page, int page_count) {
    return CollectionData::query()->equal("type", type)->sortBy(sort)->offset(page * page_count)->limit(page_count)->results();
}

gc::Ref<CollectionData> CollectionData::find(const std::string &type, const std::string &key) {
    gc::Array arr = CollectionData::query()->equal("type", type)->andQ()->equal("key", key)->results();
    if (arr->size())
        return arr->get(0);
    return gc::Ref<CollectionData>::null();
}

void CollectionData::setJSONData(const gc::Variant &data) {
    if (data) {
        nlohmann::json json = JSON::serialize(data);
        setData(json.dump());
    } else {
        setData("");
    }
}