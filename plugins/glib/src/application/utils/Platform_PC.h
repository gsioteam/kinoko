//
// Created by Gen2 on 2019-11-18.
//

#ifndef GEN_SHELF_PLATFORM_PC_H
#define GEN_SHELF_PLATFORM_PC_H

#include <libev/ev.h>
#include <map>
#include <set>
#include <core/Callback.h>

namespace gs {
    struct TimerData{
        ev_timer timer;
        gc::Callback callback;
    };

    struct PlatformPC {

        static struct ev_loop *loop;
        static ev_async async;
        static std::set<long> timers;
        static std::mutex timer_mtx;
        static bool running;

        static void timerCallback(EV_P_ ev_timer *w, int revents);

        static void asyncCallback(EV_P_ struct ev_async *w, int revents);

        PlatformPC() {}

        static void run();
        static void stop();
    };
}

#endif //GEN_SHELF_PLATFORM_PC_H
