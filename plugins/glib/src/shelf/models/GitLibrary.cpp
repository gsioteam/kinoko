//
// Created by gen on 6/12/2020.
//

#include "GitLibrary.h"
#include "../utils/SharedData.h"

using namespace gs;
using namespace gc;

namespace gc {
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

gc::Ref<GitLibrary> GitLibrary::findLibrary(const std::string &url) {
    Array res = GitLibrary::query()->equal("url", url)->results();
    if (res->size() > 0) {
        return res->get(0);
    }
    return gc::Ref<GitLibrary>::null();
}