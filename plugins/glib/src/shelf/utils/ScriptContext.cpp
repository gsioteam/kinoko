//
// Created by gen on 7/21/2020.
//

#include "ScriptContext.h"
#include <script/v8/V8Script.h>
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
        script = new V8Script(v8_root.c_str());
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
