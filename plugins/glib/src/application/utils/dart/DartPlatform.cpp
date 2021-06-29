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
    std::mutex DartPlatform::mtx;

    long timer_count = 1;
    std::mutex timer_mutex;

    gc::Ref<DartPlatform> DartPlatform::instance() {
        mtx.lock();
        Ref<DartPlatform> ins = share_instance.lock();
        if (!ins) {
            ScriptClass *cls = DartScript::instance()->find(DartPlatform::getClass());
            ins = new DartPlatform();
            cls->create(ins);
            ins->apply("control");
            share_instance = ins.get();
        }
        mtx.unlock();
        return ins;
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
    if (platform->sendSignal) {
        platform->sendSignal();
    }
}

std::string Platform::getLanguage() {
    Ref<DartPlatform> platform = DartPlatform::instance();
    Variant res;
    platform->apply("getLanguage", &res);
    return res;
}