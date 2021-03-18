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
    gc::Wk<DartPlatform> DartPlatform::share_instance;

    long timer_count = 1;
    std::mutex timer_mutex;

    void DartPlatform::setup() {
        Ref<DartPlatform> ins = share_instance.lock();
        if (!ins) {
            ScriptClass *cls = DartScript::instance()->find(DartPlatform::getClass());
            ins = new DartPlatform();
            cls->create(ins);
            ins->apply("control");
            share_instance = ins.get();
        }
    }

    void DartPlatform::clear() {
        share_instance = nullptr;
    }

    gc::Ref<DartPlatform> DartPlatform::instance() {
        return share_instance.lock();
    }

    DartPlatform::DartPlatform() {
        main_thread = pthread_self();
    }
}

long Platform::startTimer(const gc::Callback &callback, float time, bool repeat) {
    timer_mutex.lock();
    long id = timer_count++;
    timer_mutex.unlock();

    Ref<DartPlatform> platform = DartPlatform::instance();
    if (!platform) return 0;
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
    Ref<DartPlatform> platform = DartPlatform::instance();
    if (!platform) return;
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
    Ref<DartPlatform> platform = DartPlatform::instance();
    if (!platform) return;
    if (platform->sendSignal) {
        platform->sendSignal();
    }
}

void Platform::clear() {
    DartPlatform::clear();
}

void Platform::setup() {
    DartPlatform::setup();
}