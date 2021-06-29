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
#include <bit64/bit64.h>
#include "Settings.h"

extern "C" {
#include <sha1.h>
}

using namespace gs;
using namespace std;
using namespace gc;
using namespace nlohmann;

const std::string Project::nullstr;

void Project::initialize(const std::string &path) {
    dir_name = (shared::is_debug_mode ? "project" : path);
    this->path = shared::repo_path() + "/" + dir_name;
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
            if (config.contains("icon"))
                icon = config["icon"];
            if (config.contains("collections")) {
                auto cols = config["collections"];
                for (auto it = cols.begin(), _e = cols.end(); it != _e; ++it) {
                    collections.push_back(*it);
                }
            }
            if (config.contains("search")) {
                nlohmann::json sd = config["search"];
                search = sd["src"];
                if (sd.contains("data")) {
                    search_data = JSON::parse(sd["data"]);
                }
            }
            auto it = config.find("subtitle");
            if (it != config.end())
                subtitle = it.value();

            it = config.find("categories");
            if (it != config.end()) {
                Variant var = JSON::parse(it.value());
                if (var && var.getTypeClass()->isTypeOf(gc::_Array::getClass())) {
                    categories = var;
                }
            }

            validated = true;

            settings = std::shared_ptr<Settings>(new Settings(dir_name));
            if (config.contains("settings")) {
                settings_path = config["settings"];
                Ref<Context> context = createSettingsContext();
                context->enterView();
                context->exitView();
            }
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
    return Context::create(getFullpath() + "/" + index, data, Context::Project, dir_name, settings);
}

gc::Ref<Context> Project::createCollectionContext(int index, const gc::Ref<DataItem> &item) {
    if (index < collections.size()) {
        return Context::create(getFullpath() + "/" + collections[index], item, Context::Data, dir_name, settings);
    } else return Ref<Context>::null();
}

gc::Ref<Context> Project::createSearchContext() {
    return Context::create(getFullpath() + "/" + search, search_data, Context::Search, dir_name, settings);
}

gc::Ref<Context> Project::createSettingsContext() {
    return Context::create(getFullpath() + "/" + settings_path, gc::Variant::null(), Context::Setting, dir_name, settings);
}
