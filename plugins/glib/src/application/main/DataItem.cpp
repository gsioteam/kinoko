//
// Created by Gen2 on 2020-02-03.
//

#include "DataItem.h"
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
        item->raw_data = data->getData();
//        const string &jstr = data->getData();
//        if (!jstr.empty()) item->setData(JSON::parse(nlohmann::json::parse(jstr)));
        item->setProjectKey(data->getProjectKey());
    }
    return item;
}

bool DataItem::isInCollection(const std::string &type) {
    Ref<CollectionData> col = CollectionData::find(type, getProjectKey() + ":" + getLink());
    return col;
}

void DataItem::removeFromCollection(const std::string &type) {
    string key = getProjectKey() + ":" + getLink();
    Ref<CollectionData> col = CollectionData::find(type, key);
    if (col)col->remove();
}

gc::Ref<DataItem> DataItem::fromCollectionData(const gc::Ref<CollectionData> &data) {
    Ref<BookData> bdata = BookData::find(data->getTargetID());
    if (bdata) {
        return DataItem::fromData(bdata);
    }
    return gc::Ref<DataItem>::null();
}