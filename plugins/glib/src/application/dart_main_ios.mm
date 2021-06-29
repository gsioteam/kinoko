
#include "dart_main_ios.h"
#include "glib.h"
#include <script/dart/DartScript.h>
#include "utils/dart/DartPlatform.h"
#include "utils/SharedData.h"
#include "utils/database/DBMaker.h"
#include "utils/database/SQLite.h"
#include "utils/GitRepository.h"
#include "utils/Platform.h"


using namespace gscript;
using namespace gc;
using namespace gs;

namespace gs {
    OnSendSignal onSendSignal = nullptr;
}

extern "C" {

void setupLibrary(CallClass call_class, CallInstance call_instance, CreateFromNative from_native, OnSendSignal on_send_signal) {
    initGlib();
    
    DartScript::setup((Dart_CallClass)call_class, (Dart_CallInstance)call_instance, (Dart_CreateFromNative)from_native);
    
    onSendSignal = on_send_signal;
    DartPlatform::setSendSignal(C([]() {
        onSendSignal();
    }));
}
void destroyLibrary() {
    DartScript::destroy();
}
void postSetup(const char *path) {
    shared::root_path = path;
    gs::db::setup(new_t(gs::SQLite, shared::root_path + "/db.sql"));
    GitRepository::setup(shared::root_path);

    gs::DartPlatform::instance();
}
void setCacertPath(const char *path) {
    GitRepository::setCacertPath(path);
}
void runOnMainThread() {
    gs::Platform::onSignal();
}

void setDebugPath(const char *debug_path) {
    shared::is_debug_mode = true;
    shared::debug_path = debug_path;
}

}

