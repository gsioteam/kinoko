//
// Created by gen on 7/24/20.
//

#ifndef ANDROID_COLLECTIONDATA_H
#define ANDROID_COLLECTIONDATA_H

#include "../utils/database/Model.h"
#include "../gs_define.h"

namespace gs {
    CLASS_BEGIN_TN(CollectionData, Model, 1, CollectionData)

        DEFINE_STRING(type, Type);
        DEFINE_STRING(key, Key);
        DEFINE_FIELD(int, flag, Flag);

    public:

        CollectionData();

        static gc::Array all(const std::string &type);
        static gc::Ref<CollectionData> find(const std::string &type, const std::string &key);

        static void registerFields() {
            Model::registerFields();

            ADD_FILED(CollectionData, type, Type, true);
            ADD_FILED(CollectionData, key, Key, true);
            ADD_FILED(CollectionData, flag, Flag, false);
        }

    CLASS_END
}


#endif //ANDROID_COLLECTIONDATA_H
