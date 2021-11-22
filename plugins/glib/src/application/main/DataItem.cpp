//
// Created by Gen2 on 2020-02-03.
//

#include "DataItem.h"
#include "../models/CollectionData.h"

using namespace gs;
using namespace gc;
using namespace std;

bool DataItem::isInCollection(const std::string &type) {
    Ref<CollectionData> col = CollectionData::find(type, getProjectKey() + ":" + getLink());
    return col;
}

void DataItem::removeFromCollection(const std::string &type) {
    string key = getProjectKey() + ":" + getLink();
    Ref<CollectionData> col = CollectionData::find(type, key);
    if (col)col->remove();
}