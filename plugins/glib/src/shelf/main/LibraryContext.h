//
// Created by gen on 8/13/2020.
//

#ifndef ANDROID_LIBRARYCONTEXT_H
#define ANDROID_LIBRARYCONTEXT_H

#include "../models/GitLibrary.h"
#include <core/Ref.h>
#include "../gs_define.h"

namespace gs {
    CLASS_BEGIN_N(LibraryContext, gc::Object)

        gc::Array data;
        std::string token;

        gc::Ref<GitLibrary> find(const std::string &url);
        bool isMatch(const std::string &token, const std::string &url, const std::string &prev);

    public:

        LibraryContext();

        METHOD bool parseLibrary(const std::string &body);

        METHOD const gc::Array &getData() const {
            return data;
        }
        METHOD void setData(const gc::Array &data) {
            this->data = data;
        }

        ON_LOADED_BEGIN(cls, gc::Object)
            ADD_PROPERTY_EX(cls, "data", LibraryContext, getData, setData);
            ADD_METHOD(cls, LibraryContext, parseLibrary);
        ON_LOADED_END

    CLASS_END
}


#endif //ANDROID_LIBRARYCONTEXT_H
