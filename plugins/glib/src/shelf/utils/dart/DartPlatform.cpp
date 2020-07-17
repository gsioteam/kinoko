//
// Created by gen on 2020/5/31.
//

#include "DartPlatform.h"
#include <script/dart/DartScript.h>
#include "../Platform.h"

using namespace gs;
using namespace gscript;
using namespace gc;

ref_list Platform::callbacks;
Callback DartPlatform::sendSignal;
std::mutex Platform::mtx;

namespace gs {
    gc::Ref<DartPlatform> DartPlatform::share_instance = nullptr;
    std::mutex DartPlatform::mtx;

    long timer_count = 1;
    std::mutex timer_mutex;

    DartPlatform* DartPlatform::instance() {
        mtx.lock();
        if (!share_instance) {
            ScriptClass *cls = DartScript::instance()->find(DartPlatform::getClass());
            share_instance = new DartPlatform();
            cls->create(share_instance);
            share_instance->apply("control");
        }
        mtx.unlock();
        return share_instance.get();
    }

    DartPlatform::DartPlatform() {
        main_thread = pthread_self();
    }
}

long Platform::startTimer(const gc::Callback &callback, float time, bool repeat) {
    timer_mutex.lock();
    long id = timer_count++;
    timer_mutex.unlock();

    DartPlatform *platform = DartPlatform::instance();
    if (platform->isMainThread()) {
        Variant v1(callback), v2(time), v3(repeat), v4(id);
        platform->apply("startTimer", pointer_vector{&v1, &v2, &v3, &v4});
    } else {
        doOnMainThread(C([=](){
            Variant v1(callback), v2(time), v3(repeat), v4(id);
            platform->apply("startTimer", pointer_vector{&v1, &v2, &v3, &v4});
        }));
    }
    return id;
}

void Platform::cancelTimer(long timer) {
    DartPlatform *platform = DartPlatform::instance();
    if (platform->isMainThread()) {
        Variant v1(timer);
        platform->apply("cancelTimer", pointer_vector{&v1});
    } else {
        doOnMainThread(C([=](){
            Variant v1(timer);
            platform->apply("cancelTimer", pointer_vector{&v1});
        }));
    }
}

void Platform::sendSignal() {
    DartPlatform *platform = DartPlatform::instance();
    if (platform->sendSignal) {
        platform->sendSignal();
    }
}