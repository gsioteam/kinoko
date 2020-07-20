//
// Created by gen on 6/25/2020.
//

#include "KeyValue.h"

using namespace gc;
using namespace gs;

std::string KeyValue::get(const std::string &key) {
    Ref<Query> query = KeyValue::query();
    Array res = query->equal("key", key)->results();
    if (res.size() > 0) {
        Ref<KeyValue> kv = res->get(0);
        std::string val = kv->getValue();
        return val;
    }
    return std::string();
}

void KeyValue::set(const std::string &key, const std::string &value) {
    Ref<Query> query = KeyValue::query();
    Array res = query->equal("key", key)->results();
    Ref<KeyValue> kv;
    if (res.size() > 0) {
        kv = res->get(0);
    } else {
        kv = new KeyValue();
        kv->setKey(key);
    }
    kv->setValue(value);
    kv->save();
}