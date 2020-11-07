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
        DEFINE_STRING(icon, Icon);
        DEFINE_STRING(title, Title);
        DEFINE_STRING(token, Token);

    public:
        static void registerFields() {
            Model::registerFields();
            ADD_FILED(GitLibrary, url, Url, false);
            ADD_FILED(GitLibrary, date, Date, false);
            ADD_FILED(GitLibrary, icon, Icon, false);
            ADD_FILED(GitLibrary, title, Title, false);
            ADD_FILED(GitLibrary, token, Token, false);
        }
        static float version() {
            return 2;
        }

        METHOD static gc::Array allLibraries();
        METHOD static bool insertLibrary(const std::string &url);
        METHOD static gc::Ref<GitLibrary> findLibrary(const std::string &url);

        ON_LOADED_BEGIN(cls, Model<GitLibrary>)
            ADD_PROPERTY_EX(cls, url, GitLibrary, getUrl, setUrl);
            ADD_PROPERTY_EX(cls, date, GitLibrary, getDate, setDate);
            ADD_PROPERTY_EX(cls, icon, GitLibrary, getIcon, setIcon);
            ADD_PROPERTY_EX(cls, title, GitLibrary, getTitle, setTitle);
            ADD_PROPERTY_EX(cls, token, GitLibrary, getToken, setToken);
            ADD_METHOD(cls, GitLibrary, allLibraries);
            ADD_METHOD(cls, GitLibrary, insertLibrary);
            ADD_METHOD(cls, GitLibrary, findLibrary);
        ON_LOADED_END

    CLASS_END
}


#endif //ANDROID_GITLIBRARY_H
