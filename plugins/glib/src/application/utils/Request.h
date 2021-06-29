//
// Created by Gen2 on 2019-11-17.
//

#ifndef GEN_SHELF_REQUEST_H
#define GEN_SHELF_REQUEST_H

#include <core/Ref.h>
#include <string>
#include <core/Data.h>
#include <thread>
#include <core/Callback.h>
#include <core/Map.h>
#include "../gs_define.h"

namespace gs {
    class RequestImp;

    ENUM_BEGIN(BodyType)
        Raw,
        Mutilpart,
        UrlEncode
    ENUM_END

    CLASS_BEGIN_N(Request, gc::Object)

        std::string url;
        gc::StringName method;
        BodyType bodyType;

        RequestImp *imp;

        friend class RequestImp;

    public:

        static const gc::StringName GET;
        static const gc::StringName POST;
        static const gc::StringName DELETE;
        static const gc::StringName PUT;
        static const gc::StringName HEADER;
        static const gc::StringName OPTIONS;

        Request();
        ~Request();

        METHOD _FORCE_INLINE_ void initialize(const gc::StringName &method, const std::string &url, BodyType type = Raw) {
            this->url = url;
            this->method = method;
            this->bodyType = type;
        }
        METHOD void setHeader(const std::string &name, const std::string &value);
        METHOD void setBody(const gc::Ref<gc::Data> &body);
        METHOD void setTimeout(uint64_t timeout);
        METHOD int getStatusCode();
        METHOD int64_t getUploadTotal() const;
        METHOD int64_t getUploadNow() const;
        METHOD int64_t getDownloadTotal() const;
        METHOD int64_t getDownloadNow() const;

        METHOD void setOnUploadProgress(const gc::Callback &on_progress);
        METHOD void setOnProgress(const gc::Callback &on_progress);
        METHOD void setOnComplete(const gc::Callback & on_complete);
        METHOD void setOnResponse(const gc::Callback & on_response);

        METHOD void setCacheResponse(bool cache_response);

        METHOD gc::Ref<gc::Data> getResponseBody();
        METHOD gc::Ref<gc::Map> getResponseHeaders();
        METHOD std::string getError();
        METHOD std::string getResponseUrl();

        METHOD void start();
        METHOD void cancel();

    protected:
        ON_LOADED_BEGIN(cls, gc::Object)
            ADD_METHOD_D(cls, Request, initialize, Raw);
            ADD_METHOD(cls, Request, setOnUploadProgress);
            ADD_METHOD(cls, Request, setOnProgress);
            ADD_METHOD(cls, Request, setOnComplete);
            ADD_METHOD(cls, Request, setOnResponse);
            ADD_METHOD(cls, Request, setHeader);
            ADD_METHOD(cls, Request, setBody);
            ADD_METHOD(cls, Request, setTimeout);
            ADD_METHOD(cls, Request, getStatusCode);
            ADD_METHOD(cls, Request, getUploadTotal);
            ADD_METHOD(cls, Request, getUploadNow);
            ADD_METHOD(cls, Request, getDownloadTotal);
            ADD_METHOD(cls, Request, getDownloadNow);
            ADD_METHOD(cls, Request, getResponseBody);
            ADD_METHOD(cls, Request, getResponseHeaders);
            ADD_METHOD(cls, Request, setCacheResponse);
            ADD_METHOD(cls, Request, getError);
            ADD_METHOD(cls, Request, getResponseUrl);
            ADD_METHOD(cls, Request, start);
            ADD_METHOD(cls, Request, cancel);
        ON_LOADED_END
    CLASS_END
}


#endif //GEN_SHELF_REQUEST_H
