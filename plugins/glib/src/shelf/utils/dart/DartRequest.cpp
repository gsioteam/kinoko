//
// Created by gen on 2020/5/22.
//

#include "DartRequest.h"
#include "../Request.h"
#include <script/dart/DartScript.h>

using namespace gs;
using namespace gc;
using namespace gscript;

namespace gs {
    class RequestImp {

        Ref<DartRequest> request;
        Request *tar;

    public:
        Ref<DartRequest> req() {
            if (!request) {
                ScriptClass *cls = DartScript::instance()->find(DartRequest::getClass());
                request = new DartRequest();
                cls->create(request);
                Variant v1(tar->method), v2(tar->url), v3(tar->bodyType);
                request->apply("setup", pointer_vector{&v1, &v2, &v3});
            }
            return request;
        }

        RequestImp(Request *req) : tar(req) {

        }

        ~RequestImp() {
            if (request) {
                request->apply("release");
            }
        }
    };
}

Request::Request() {
    imp = new RequestImp(this);
}

Request::~Request() {
    delete imp;
}

void Request::setHeader(const std::string &name, const std::string &value) {
    Variant v1(name), v2(value);
    imp->req()->apply("setHeader", pointer_vector{&v1, &v2});
}

void Request::setBody(const gc::Ref<gc::Data> &body) {
    b8_vector v = body->readAll();
    Variant v1(v.data()), v2(v.size());
    imp->req()->apply("setBody", pointer_vector{&v1, &v2});
}

void Request::start() {
    imp->req()->apply("start");
}

void Request::cancel() {
    imp->req()->apply("cancel");
}

void Request::setTimeout(uint64_t timeout) {
    Variant v1 = timeout;
    imp->req()->apply("setTimeout", pointer_vector{&v1});
}

int64_t Request::getUploadNow() const {
    return imp->req()->apply("getUploadNow", pointer_vector());
}

int64_t Request::getUploadTotal() const {
    return imp->req()->apply("getUploadTotal", pointer_vector());
}

int64_t Request::getDownloadNow() const {
    return imp->req()->apply("getDownloadNow", pointer_vector());
}

int64_t Request::getDownloadTotal() const {
    return imp->req()->apply("getDownloadTotal", pointer_vector());
}

void Request::setOnUploadProgress(const gc::Callback &on_progress) {
    Variant v1 = on_progress;
    imp->req()->apply("setOnUploadProgress", pointer_vector{&v1});
}

void Request::setOnProgress(const gc::Callback &on_progress) {
    Variant v1 = on_progress;
    imp->req()->apply("setOnProgress", pointer_vector{&v1});
}

void Request::setOnComplete(const gc::Callback &on_complete) {
    Variant v1 = on_complete;
    imp->req()->apply("setOnComplete", pointer_vector{&v1});
}

gc::Ref<gc::Data> Request::getResponseBody() {
    return imp->req()->apply("getResponseBody", pointer_vector());
}

gc::Ref<gc::Map> Request::getResponseHeaders() {
    return imp->req()->apply("getResponseHeaders", pointer_vector());
}

const std::string& Request::getError() {
    return imp->req()->apply("getError", pointer_vector());
}