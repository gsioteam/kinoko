//
// Created by Gen2 on 2020/5/17.
//

#include "Request.h"
#include "../android/Object.h"

using namespace gs;
using namespace gc;

namespace gs {
    class RequestImp : public JavaObject {

    public:

        Callback onProgress;
        Callback onUploadProgress;

        size_t upload_total = 0;
        size_t upload_now = 0;
        size_t progress_total = 0;
        size_t progress_now = 0;

        void addHeader(const std::string &name, const std::string &value) {
            this->callMethod("addHeader", variant_vector{name, value});
        }

        void setBody(const gc::Ref<gc::Data> &body) {
            this->callMethod("setBody", variant_vector{body});
        }

        void setTimeout(int32_t timeout) {
            this->callMethod("setTimeout", variant_vector{timeout});
        }

        void setOnComplete(Callback callback) {
            this->callMethod("setOnComplete", variant_vector{callback});
        }

        Ref<Data> getResponseBody() {
            return this->callMethod("getResponseBody");
        }

        Ref<Map> getResponseHeaders() {
            return this->callMethod("getResponseHeaders");
        }

        void start() {
            this->callMethod("setOnProgress", variant_vector{C([=](size_t now, size_t total){
                progress_total = total;
                progress_now = now;
                if (onProgress) onProgress(now, total);
            })});
            this->callMethod("onUploadProgress", variant_vector{C([=](size_t now, size_t total){
                upload_total = total;
                upload_now = now;
                if (onUploadProgress) onUploadProgress(now, total);
            })});
            this->callMethod("start");
        }

        void cancel() {
            this->callMethod("cancel");
        }
    };
}

Request::Request() {
    imp = RequestImp::create<RequestImp>("com/qlp/gs/Request");
}

Request::~Request() {
    delete imp;
}

void Request::setHeader(const std::string &name, const std::string &value) {
    imp->addHeader(name, value);
}

void Request::setBody(const gc::Ref<gc::Data> &body) {
    imp->setBody(body);
}
void Request::setTimeout(uint64_t timeout) {
    imp->setTimeout((int32_t)timeout);
}

int64_t Request::getUploadTotal() const {
    return imp->upload_total;
}

int64_t Request::getUploadNow() const {
    return imp->upload_now;
}

int64_t Request::getDownloadNow() const {
    return imp->progress_now;
}

int64_t Request::getDownloadTotal() const {
    return imp->progress_total;
}


void Request::setOnUploadProgress(const gc::Callback &on_progress) {
    imp->onUploadProgress = on_progress;
}
void Request::setOnProgress(const gc::Callback &on_progress) {
    imp->onProgress = on_progress;
}
void Request::setOnComplete(const gc::Callback & on_complete) {
    imp->setOnComplete(on_complete);
}

gc::Ref<gc::Data> Request::getResponseBody() {
    return imp->getResponseBody();
}

gc::Ref<gc::Map> Request::getResponseHeaders() {
    return imp->getResponseHeaders();
}

void Request::start() {
    imp->start();
}

void Request::cancel() {
    imp->cancel();
}