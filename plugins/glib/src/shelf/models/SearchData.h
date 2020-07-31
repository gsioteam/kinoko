//
// Created by gen on 7/31/2020.
//

#ifndef ANDROID_SEARCHDATA_H
#define ANDROID_SEARCHDATA_H

#include "../utils/database/Model.h"
#include "../gs_define.h"

namespace gs {
    CLASS_BEGIN_TN(SearchData, Model, 1, SearchData)

        DEFINE_STRING(key, Key);
        DEFINE_FIELD(long long, date, Date);

    public:

        static void registerFields() {
            Model::registerFields();
            ADD_FILED(SearchData, key, Key, true);
            ADD_FILED(SearchData, date, Date, true);
        }

        static void insert(const std::string &key, long long date);

    CLASS_END
}


#endif //ANDROID_SEARCHDATA_H
