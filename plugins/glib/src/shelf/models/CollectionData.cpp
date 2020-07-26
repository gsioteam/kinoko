//
// Created by gen on 7/24/20.
//

#include "CollectionData.h"

using namespace gs;

CollectionData::CollectionData() : flag(0) {
}

gc::Array CollectionData::all(const std::string &type) {
    return CollectionData::query()->equal("type", type)->sortBy("identifier")->results();
}

gc::Ref<CollectionData> CollectionData::find(const std::string &type, int target_id) {
    gc::Array arr = CollectionData::query()->equal("type", type)->andQ()->equal("target_id", target_id)->results();
    if (arr->size())
        return arr->get(0);
    return gc::Ref<CollectionData>::null();
}