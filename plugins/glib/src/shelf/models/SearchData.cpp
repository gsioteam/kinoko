//
// Created by gen on 7/31/2020.
//

#include "SearchData.h"

using namespace gs;
using namespace gc;

void SearchData::insert(const std::string &key, long long date) {
    auto query = SearchData::query();
    ref_vector res = query->equal("key", key)->res();
    Ref<SearchData> data;
    if (res.empty()) {
        data = new SearchData();
        data->setKey(key);
    } else {
        data = res[0];
    }
    data->setDate(date);
    data->save();
}