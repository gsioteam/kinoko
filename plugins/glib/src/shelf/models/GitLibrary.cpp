//
// Created by gen on 6/12/2020.
//

#include "GitLibrary.h"
#include "../utils/YAML.h"
#include "../utils/SharedData.h"
#include <secp256k1.h>

using namespace gs;
using namespace gc;

namespace gc {
    std::time_t getTimeStamp()
    {
        std::chrono::time_point<std::chrono::system_clock,std::chrono::milliseconds> tp = std::chrono::time_point_cast<std::chrono::milliseconds>(std::chrono::system_clock::now());//获取当前时间点
        std::time_t timestamp =  tp.time_since_epoch().count(); //计算距离1970-1-1,00:00的时间长度
        return timestamp;
    }
}

gc::Array GitLibrary::allLibraries() {
    auto query = GitLibrary::query();
    gc::Array res = query->sortBy("date")->results();
//    if (res.size() == 0) {
//        {
//            Ref<GitLibrary> lib(new_t(GitLibrary));
//            lib->setUrl("https://github.com/gsioteam/pro1.git");
//            lib->setDate(getTimeStamp());
//            lib->save();
//            res.push_back(lib);
//        }
//    }
    return res;
}

bool GitLibrary::insertLibrary(const std::string &url) {
    Array res = GitLibrary::query()->equal("url", url)->results();
    if (res->size() > 0) {
        return false;
    }
    Ref<GitLibrary> lib = new GitLibrary;
    lib->setUrl(url);
    lib->setDate(getTimeStamp());
    lib->save();
    return true;
}

gc::Ref<GitLibrary> GitLibrary::parseLibrary(const std::string &str, const std::string &prev) {
    yaml data = yaml::parse(str);
    if (data.is_map()) {
        std::string token = data["token"];
        std::string url = data["url"];
        if (url.empty() || token.empty()) {
            return nullptr;
        }

    }
}