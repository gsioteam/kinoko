//
// Created by gen on 7/24/20.
//

#include "CollectionData.h"

using namespace gs;

CollectionData::CollectionData() : flag(0) {
}

gc::Array CollectionData::all(const std::string &type) {
    return CollectionData::query()->equal("type", type)->results();
}

gc::Ref<CollectionData> CollectionData::find(const std::string &type, const std::string &key) {
    gc::Array arr = CollectionData::query()->equal("type", type)->andQ()->equal("key", key)->results();
    if (arr->size())
        return arr->get(0);
    return gc::Ref<CollectionData>::null();
}