//
// Created by gen on 8/17/20.
//

#include "Settings.h"
#include "../utils/SharedData.h"
#include "../models/KeyValue.h"
#include "../utils/JSON.h"

using namespace gs;
using namespace gc;


bool Settings::exist() const {
    std::string value = KeyValue::get(shared::SETTING_KEY + project_key);
    return !value.empty();
}

void Settings::load() {
    std::string value = KeyValue::get(shared::SETTING_KEY + project_key);
    if (!value.empty()) {
        Variant var = JSON::parse(nlohmann::json::parse(value));
        if (var.getType() == Variant::TypeReference &&
            var.getTypeClass()->isTypeOf(gc::_Map::getClass())) {
            map = var;
        }
    }
}

const gc::Variant &Settings::get(const std::string &key) {
    if (!init) {
        load();
        init = true;
    }
    return map->get(key);
}

void Settings::set(const std::string &key, const gc::Variant &value) {
    if (!init) {
        load();
        init = true;
    }
    map->set(key, value);
}

void Settings::save() {
    nlohmann::json json = JSON::serialize(map);
    KeyValue::set(shared::SETTING_KEY + project_key, json.dump());
}

void SettingItem::initialize(
        SettingType type,
        const std::string &name,
        const std::string &title,
        const gc::Variant &default_value,
        const gc::Variant &data) {
    this->type = type;
    this->name = name;
    this->title = title;
    this->default_value = default_value;
    this->data = data;
}