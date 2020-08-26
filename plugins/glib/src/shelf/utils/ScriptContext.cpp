//
// Created by gen on 7/21/2020.
//

#include "ScriptContext.h"

#ifdef __APPLE__
#include <script/js_core/JSCoreScript.h>
#endif

#ifdef __ANDROID__
#include <script/v8/V8Script.h>
#endif

#include <script/ruby/RubyScript.h>
#include "SharedData.h"

using namespace gs;
using namespace gc;
using namespace std;
using namespace gscript;

namespace gs {
    const StringName V8_KEY("v8");
    const StringName RUBY_KEY("ruby");
}

void ScriptContext::initialize(const gc::StringName &type) {
    if (type == V8_KEY) {
        string v8_root = shared::repo_path() + "/env/v8";
#ifdef __APPLE__
        script = new JSCoreScript(v8_root.c_str());
#endif
#ifdef __ANDROID__
        script = new V8Script(v8_root.c_str());
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
        delete script;
    }
}
