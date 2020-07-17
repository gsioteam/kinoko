//
// Created by gen on 6/12/2020.
//

#ifndef ANDROID_GITLIBRARY_H
#define ANDROID_GITLIBRARY_H

#include "../utils/database/Model.h"
#include "../gs_define.h"

namespace gs {
    CLASS_BEGIN_TN(GitLibrary, Model, 1, GitLibrary)

        DEFINE_STRING(url, Url);
        DEFINE_FIELD(long long, date, Date);

    public:
        static void registerFields() {
            Model::registerFields();
            ADD_FILED(GitLibrary, url, Url, false);
            ADD_FILED(GitLibrary, date, Date, false);
        }

        METHOD static gc::Array allLibraries();
        METHOD static bool insertLibrary(const std::string &url);

        ON_LOADED_BEGIN(cls, Model<GitLibrary>)
            ADD_PROPERTY_EX(cls, url, GitLibrary, getUrl, setUrl);
            ADD_PROPERTY_EX(cls, date, GitLibrary, getDate, setDate);
            ADD_METHOD(cls, GitLibrary, allLibraries);
            ADD_METHOD(cls, GitLibrary, insertLibrary);
        ON_LOADED_END

    CLASS_END
}


#endif //ANDROID_GITLIBRARY_H
