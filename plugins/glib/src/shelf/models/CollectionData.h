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
        DEFINE_FIELD(int, target_id, TargetID);
        DEFINE_FIELD(int, flag, Flag);

    public:

        CollectionData();

        METHOD static gc::Array all(const std::string &type);
        static gc::Ref<CollectionData> find(const std::string &type, int target_id);

        static void registerFields() {
            Model::registerFields();

            ADD_FILED(CollectionData, type, Type, true);
            ADD_FILED(CollectionData, target_id, TargetID, true);
            ADD_FILED(CollectionData, flag, Flag, false);
        }

        ON_LOADED_BEGIN(cls, Model)
            ADD_METHOD(cls, CollectionData, all);
            ADD_PROPERTY(cls, "flag", ADD_METHOD(cls, CollectionData, getFlag), ADD_METHOD(cls, CollectionData, setFlag));
        ON_LOADED_END

    CLASS_END
}


#endif //ANDROID_COLLECTIONDATA_H
