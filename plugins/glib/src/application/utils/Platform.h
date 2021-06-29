//
// Created by Gen2 on 2019-11-18.
//

#ifndef GEN_SHELF_PLATFORM_H
#define GEN_SHELF_PLATFORM_H

#include <core/Callback.h>
#include "../gs_define.h"

namespace gs {

    CLASS_BEGIN_0_N(Platform)
        static ref_list callbacks;
        static std::mutex mtx;

        static void sendSignal();

    public:

        static void onSignal() {
            mtx.lock();
            for (auto it = callbacks.begin(), _e = callbacks.end(); it != _e; ++it) {
                gc::Callback cb = *it;
                cb();
            }
            callbacks.clear();
            mtx.unlock();
        }

        static void doOnMainThread(const gc::Callback &callback) {
            mtx.lock();
            callbacks.push_back(callback);
            mtx.unlock();
            sendSignal();
        }

        static long startTimer(const gc::Callback &callback, float time, bool repeat = false);
        static void cancelTimer(long timer);

        static std::string getLanguage();

        ON_LOADED_BEGIN(cls, gc::Object)
            ADD_METHOD_D(cls, Platform, startTimer, false);
            ADD_METHOD(cls, Platform, cancelTimer);
        ON_LOADED_END

    CLASS_END
}



#endif //GEN_SHELF_PLATFORM_H
