//
// Created by gen on 3/20/21.
//

#include "DartBrowser.h"
#include <script/dart/DartScript.h>
#include <core/Callback.h>

using namespace gs;
using namespace gc;
using namespace gscript;

namespace gs {


    class BrowserImp {

        Ref<DartBrowser> imp;
        Browser *tar;

    public:
        BrowserImp(Browser *tar) : tar(tar) {}

        Ref<DartBrowser> get() {
            if (!imp) {
                ScriptClass *cls = DartScript::instance()->find(DartBrowser::getClass());
                imp = new DartBrowser();
                cls->create(imp);
                Variant v1(tar->url), v2(tar->rules), v3(tar->hidden);
                imp->apply("setup", pointer_vector{&v1, &v2, &v3});
            }
            return imp;
        }

    };
}

Browser::Browser() {
    imp = new BrowserImp(this);
}

Browser::~Browser() noexcept {
    delete imp;
}

void Browser::setUserAgent(const std::string &ua) {
    NAME(setUserAgent);
    Variant var(ua);
    imp->get()->apply(setUserAgent, pointer_vector{&var});
}

void Browser::start() {
    NAME(start);
    imp->get()->apply(start);
}

void Browser::setOnComplete(const gc::Callback &callback) {
    NAME(setOnComplete);
    Variant var(callback);
    imp->get()->apply(setOnComplete, pointer_vector{&var});
}

std::string Browser::getError() {
    NAME(getError);
    return imp->get()->apply(getError, pointer_vector());
}