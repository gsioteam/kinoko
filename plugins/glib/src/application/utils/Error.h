//
// Created by gen on 7/2/2020.
//

#ifndef ANDROID_ERROR_H
#define ANDROID_ERROR_H

#include <core/Ref.h>
#include "../gs_define.h"

namespace gs {
    CLASS_BEGIN_N(Error, gc::Object)

        int code;
        std::string msg;

    public:
        void initialize(int code, const std::string &msg) {
            this->code = code;
            this->msg = msg;
        }

        METHOD int getCode() const {
            return code;
        }
        METHOD void setCode(int code) {
            this->code = code;
        }
        PROPERTY(code, getCode, setCode);

        METHOD const std::string &getMsg() const {
            return msg;
        }
        METHOD void setMsg(const std::string &msg) {
            this->msg = msg;
        }
        PROPERTY(msg, getMsg, setMsg);

        ON_LOADED_BEGIN(cls, gc::Object)
            INITIALIZER(cls, Error, initialize);
            ADD_PROPERTY(cls, "code", ADD_METHOD(cls, Error, getCode), ADD_METHOD(cls, Error, setCode));
            ADD_PROPERTY(cls, "msg", ADD_METHOD(cls, Error, getMsg), ADD_METHOD(cls, Error, setMsg));
        ON_LOADED_END

    CLASS_END
}


#endif //ANDROID_ERROR_H
