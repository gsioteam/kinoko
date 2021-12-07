
#include "dart_main_ios.h"
#include "glib.h"
#include <script/dart/DartScript.h>
#include "utils/database/DBMaker.h"
#include "utils/database/SQLite.h"


using namespace gscript;
using namespace gc;
using namespace gs;

namespace gs {
    OnSendSignal onSendSignal = nullptr;
}

extern "C" {

void* setupLibrary(CallClass call_class, CallInstance call_instance, CreateFromNative from_native, OnSendSignal on_send_signal) {
    initGlib();
    
    DartScript *script = new DartScript();
    script->setup((Dart_CallClass)call_class, (Dart_CallInstance)call_instance, (Dart_CreateFromNative)from_native);
    return script;
}
void destroyLibrary(void *script) {
    delete (DartScript *)script;
}
void postSetup(const char *path) {
    std::string root_path = path;
    gs::db::setup(new_t(gs::SQLite, root_path + "/db.sql"));

}
void setCacertPath(const char *path) {
}
void runOnMainThread() {
}

}

