//
// Created by Gen2 on 2020/5/12.
//

#include "Platform.h"
#include "../android/Object.h"

using namespace gs;
using namespace gc;

namespace gs {
    JavaObject *platform_instance = NULL;
    std::mutex _mtx;

    JavaObject *platformInstance() {
        _mtx.lock();
        if (!platform_instance) {
            platform_instance = JavaObject::create("com/qlp/gs/Platform");
            platform_instance->callMethod("setSignalHandler", variant_vector{C([](){
                Platform::onSignal();
            })});
        }
        _mtx.unlock();
        return platform_instance;
    }
}
ref_list Platform::callbacks;
std::mutex Platform::mtx;

void Platform::sendSignal() {
    platformInstance()->callMethod("sendSignal");
}

long Platform::startTimer(const gc::Callback &callback, float time, bool repeat) {
    return platformInstance()->callMethod("startTimer", variant_vector{callback, time, repeat});
}

void Platform::cancelTimer(long timer) {
    platformInstance()->callMethod("cancelTimer", variant_vector{timer});
}