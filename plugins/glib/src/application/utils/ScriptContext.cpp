//
// Created by gen on 7/21/2020.
//

#include "ScriptContext.h"
#include "Platform.h"

#ifdef __APPLE__
#include <script/js_core/JSCoreScript.h>
#endif

#ifdef __ANDROID__
#include <script/quickjs/QuickJSScript.h>
#endif

#include <script/ruby/RubyScript.h>
#include "SharedData.h"

using namespace gs;
using namespace gc;
using namespace std;
using namespace gscript;

namespace gs {
    const StringName V8_KEY("v8");
    const StringName JS_KEY("js");
    const StringName QJS_KEY("quickjs");
    const StringName RUBY_KEY("ruby");
}

void ScriptContext::initialize(const gc::StringName &type) {
    if (type == V8_KEY || type == JS_KEY || type == QJS_KEY) {
        string v8_root = shared::repo_path() + "/env/v8";
#ifdef __APPLE__
        script = new JSCoreScript(v8_root.c_str());
#endif
#ifdef __ANDROID__
        QuickJSScript *qjs = new QuickJSScript(v8_root.c_str());
        script = qjs;
        timer = Platform::startTimer(C([=]() {
            qjs->Step();
        }), 0.05f, true);
#endif
    } else if (type == RUBY_KEY) {
        script = new RubyScript();
    }
}

gc::Variant ScriptContext::eval(const std::string &src) {
    return script->runScript(src.c_str());
}

ScriptContext::~ScriptContext() {
    if (script) {
#ifdef __ANDROID__
        Platform::cancelTimer(timer);
#endif
        delete script;
    }
}
