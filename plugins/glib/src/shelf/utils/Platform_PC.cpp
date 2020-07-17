//
// Created by Gen2 on 2019-11-18.
//

#include "Platform.h"
#include "Platform_PC.h"
#include <mutex>

using namespace gs;
using namespace gc;
using namespace std;


mutex gs::Platform::mtx;
ref_list gs::Platform::callbacks;

struct ev_loop *PlatformPC::loop = ev_loop_new(EVFLAG_AUTO);
ev_async PlatformPC::async;
std::set<long> PlatformPC::timers;
std::mutex PlatformPC::timer_mtx;
bool PlatformPC::running = false;

void gs::Platform::sendSignal() {
    ev_async_send(PlatformPC::loop, &PlatformPC::async);
}

void PlatformPC::timerCallback(EV_P_ ev_timer *w, int revents) {
    TimerData *data = (TimerData *)w->data;
    data->callback((long)data);
}

void PlatformPC::asyncCallback(EV_P_ struct ev_async *w, int revents) {
    Platform::onSignal();
}

void PlatformPC::run() {
    if (!running) {
        running = true;

        ev_async_init(&async, PlatformPC::asyncCallback);
        ev_async_start(loop, &async);

        ev_run(loop, 0);

    }else {
        LOG(e, "Already running");
    }
}

void PlatformPC::stop() {
    ev_break(PlatformPC::loop,  EVBREAK_ONE);
}

long Platform::startTimer(const gc::Callback &callback, float time, bool repeat) {
    unique_lock<decltype(PlatformPC::timer_mtx)> lock(PlatformPC::timer_mtx);
    TimerData *data = new TimerData();
    data->callback = callback;
    ev_timer_init(&data->timer, &PlatformPC::timerCallback, time, repeat);
    data->timer.data = data;
    PlatformPC::timers.insert((long)data);
    ev_timer_start(PlatformPC::loop, &data->timer);

    return (long)data;
}

void Platform::cancelTimer(long timer) {
    unique_lock<decltype(PlatformPC::timer_mtx)> lock(PlatformPC::timer_mtx);
    if (PlatformPC::timers.count(timer)) {
        TimerData *data = (TimerData *)timer;
        ev_timer_stop(PlatformPC::loop, &data->timer);
        PlatformPC::timers.erase(timer);
        delete data;
    }
}