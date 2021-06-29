//
// Created by gen on 3/20/21.
//

#ifndef ANDROID_BROWSER_H
#define ANDROID_BROWSER_H

#include <core/Ref.h>
#include "../gs_define.h"

namespace gs {
    class BrowserImp;

    CLASS_BEGIN_N(Browser, gc::Object)

        BrowserImp *imp;
        std::string url;
        std::string rules;
        bool hidden;

        friend class BrowserImp;

    public:
        Browser();
        ~Browser();

        METHOD _FORCE_INLINE_ void initialize(const std::string &url, const std::string &rules, bool hidden) {
            this->url = url;
            this->rules = rules;
            this->hidden = hidden;
        }

        METHOD void setUserAgent(const std::string &ua);
        METHOD void start();
        METHOD void setOnComplete(const gc::Callback &callback);
        METHOD std::string getError();

        ON_LOADED_BEGIN(cls, gc::Object)
            ADD_METHOD(cls, Browser, initialize);
            ADD_METHOD(cls, Browser, start);
            ADD_METHOD(cls, Browser, setOnComplete);
            ADD_METHOD(cls, Browser, getError);
            ADD_METHOD(cls, Browser, setUserAgent);
        ON_LOADED_END

    CLASS_END
}

#endif //ANDROID_BROWSER_H
