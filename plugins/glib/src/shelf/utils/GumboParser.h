//
// Created by Gen2 on 2020-01-31.
//

#ifndef EV_GUMBOPARSER_H
#define EV_GUMBOPARSER_H

#include <core/Ref.h>
#include <core/Array.h>
#include <core/Data.h>
#include "../gs_define.h"

namespace gs {

    class Gumbo;

    CLASS_BEGIN_NV(GumboNode, gc::Object)

        gc::Ref<Gumbo> gumbo;
        void *n;

        GumboNode(const gc::Ref<Gumbo> &gumbo);

    public:

        METHOD static gc::Ref<GumboNode> parse(const gc::Ref<gc::Data> &data, const char *encode = nullptr);

        METHOD std::string getTagName();
        METHOD gc::Array query(const std::string &css);
        METHOD std::string getText();

        METHOD gc::Ref<GumboNode> parent();
        METHOD size_t childCount();
        METHOD gc::Ref<GumboNode> childAt(size_t i);

        METHOD std::string getAttribute(const std::string &name);

    protected:
        ON_LOADED_BEGIN(cls, gc::Object)
            ADD_METHOD_D(cls, GumboNode, parse, NULL);
            ADD_METHOD(cls, GumboNode, getTagName);
            ADD_METHOD(cls, GumboNode, query);
            ADD_METHOD(cls, GumboNode, getText);
            ADD_METHOD(cls, GumboNode, parent);
            ADD_METHOD(cls, GumboNode, childCount);
            ADD_METHOD(cls, GumboNode, childAt);
            ADD_METHOD(cls, GumboNode, getAttribute);
        ON_LOADED_END
    CLASS_END

}
#endif //EV_GUMBOPARSER_H
