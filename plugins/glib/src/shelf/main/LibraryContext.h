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
        METHOD bool insertLibrary(const std::string &url);
        METHOD bool removeLibrary(const std::string &url);

        METHOD const gc::Array &getData() const {
            return data;
        }
        METHOD void setData(const gc::Array &data) {
            this->data = data;
        }

        METHOD void reset();

        ON_LOADED_BEGIN(cls, gc::Object)
            ADD_PROPERTY_EX(cls, "data", LibraryContext, getData, setData);
            ADD_METHOD(cls, LibraryContext, parseLibrary);
            ADD_METHOD(cls, LibraryContext, insertLibrary);
            ADD_METHOD(cls, LibraryContext, removeLibrary);
            ADD_METHOD(cls, LibraryContext, reset);
        ON_LOADED_END

    CLASS_END
}


#endif //ANDROID_LIBRARYCONTEXT_H
