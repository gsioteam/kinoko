//
// Created by Gen2 on 2019-11-18.
//

#ifndef GEN_SHELF_PLATFORM_H
#define GEN_SHELF_PLATFORM_H

#include <core/Callback.h>

namespace gs {

    class Platform {
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

        static void setup();
        static void clear();
    };
}



#endif //GEN_SHELF_PLATFORM_H
