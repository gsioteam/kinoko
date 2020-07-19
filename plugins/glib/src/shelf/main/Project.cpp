//
// Created by gen on 6/23/2020.
//

#include "Project.h"
#include <sstream>
#include "../utils/JSON.h"
#include "../utils/SharedData.h"
#include <core/Map.h>
#include "Context.h"
#include "DataItem.h"
#include "../models/KeyValue.h"

using namespace gs;
using namespace std;
using namespace gc;
using namespace nlohmann;

void Project::initialize(const std::string &path) {
    dir_name = path;
    this->path = shared::repo_path() + "/" + (shared::is_debug_mode ? "project" : path);
    validated = false;
    stringstream ss;
    string config_path = this->path + "/config.json";
    FILE *file = fopen(config_path.c_str(), "r");
    if (file) {
#define B_SIZE 2048
        size_t readed = 0;
        char buf[B_SIZE];
        while ((readed = fread(buf, 1, B_SIZE, file)) > 0) {
            ss.write(buf, readed);
        }
        fclose(file);

        try {
            config = nlohmann::json::parse(ss.str());
            name = config["name"];
            url = config["url"];
            index = config["index"];
            book = config["book"];
            auto it = config.find("subtitle");
            if (it != config.end()) {
                subtitle = it.value();
            }

            it = config.find("categories");
            if (it != config.end()) {
                Variant var = JSON::parse(it.value());
                if (var && var.getTypeClass()->isTypeOf(gc::_Array::getClass())) {
                    categories = var;
                }
            }

            validated = true;
        } catch (exception &e) {
            LOG(e, "%s", e.what());
        }
    } else {
    }

}

gc::Ref<Project> Project::getMainProject() {
    std::string name = KeyValue::get(shared::MAIN_PROJECT_KEY);
    if (!name.empty()) {
        Ref<Project> pro(new_t(Project, name));
        if (pro->isValidated()) return pro;
    }
    return nullptr;
}

void Project::setMainProject() {
    KeyValue::set(shared::MAIN_PROJECT_KEY, dir_name);
}

gc::Ref<Context> Project::createIndexContext(const gc::Variant &data) {
    gc::Map map = data;
    std::string key;
    if (map) {
        Variant vid = map->get("id");
        key = url + ":" + vid.str();
    } else {
        key = "unkown";
        LOG(w, "No id found in data");
    }
    return Context::create(getFullpath() + "/" + index, data, ContextProject, key);
}

gc::Ref<Context> Project::createBookContext(const gc::Ref<DataItem> &item) {
    return Context::create(getFullpath() + "/" + book, item, ContextBook, item->getLink());
}