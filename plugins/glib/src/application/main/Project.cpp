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
#include <unistd.h>
#include <dirent.h>
#include <sys/stat.h>
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

bool Project::setMainProject() {
    if (!target.empty() && target != shared::version) {
        return false;
    }
    KeyValue::set(shared::MAIN_PROJECT_KEY, dir_name);
    return true;
}

int remove_directory(const char *path) {
    DIR *d = opendir(path);
    size_t path_len = strlen(path);
    int r = -1;

    if (d) {
        struct dirent *p;

        r = 0;
        while (!r && (p=readdir(d))) {
            int r2 = -1;
            char *buf;
            size_t len;

            /* Skip the names "." and ".." as we don't want to recurse on them. */
            if (!strcmp(p->d_name, ".") || !strcmp(p->d_name, ".."))
                continue;

            len = path_len + strlen(p->d_name) + 2;
            buf = (char *)malloc(len);

            if (buf) {
                struct stat statbuf;

                snprintf(buf, len, "%s/%s", path, p->d_name);
                if (!stat(buf, &statbuf)) {
                    if (S_ISDIR(statbuf.st_mode))
                        r2 = remove_directory(buf);
                    else
                        r2 = unlink(buf);
                }
                free(buf);
            }
            r = r2;
        }
        closedir(d);
    }

    if (!r)
        r = rmdir(path);

    return r;
}

void Project::remove() {
    if (KeyValue::get(shared::MAIN_PROJECT_KEY) == dir_name) {
        KeyValue::set(shared::MAIN_PROJECT_KEY, "");
    }
    int ret = remove_directory(path.c_str());
    if (ret) {
        LOG(i, "Remove directory failed %s", path.c_str());
    }
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
