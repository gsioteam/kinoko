//
// Created by gen on 2020/5/31.
//

#ifndef ANDROID_DARTPLATFORM_H
#define ANDROID_DARTPLATFORM_H

#include <core/Ref.h>
#include <pthread.h>
#include <core/Callback.h>
#include "../../gs_define.h"

namespace gs {
    CLASS_BEGIN_N(DartPlatform, gc::Object)
        static gc::Wk<DartPlatform> share_instance;
        static std::mutex mtx;
        static gc::Callback sendSignal;
        pthread_t main_thread;
        friend class Platform;

    public:
        static gc::Ref<DartPlatform> instance();

        DartPlatform();

        bool isMainThread() {
            return main_thread == pthread_self();
        }

        static void setSendSignal(const gc::Callback &sendSignal) {
            DartPlatform::sendSignal = sendSignal;
        }

    CLASS_END
}


#endif //ANDROID_DARTPLATFORM_H
