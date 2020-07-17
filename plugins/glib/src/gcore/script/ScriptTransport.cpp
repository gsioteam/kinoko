//
//  ScriptTransport.cpp
//  hirender_iOS
//
//  Created by Gen on 16/10/5.
//  Copyright © 2016年 gen. All rights reserved.
//

#include <core/Callback.h>
#include "ScriptTransport.h"

using namespace gscript;

ref_map ScriptTransport::callbacks;

void ScriptTransport::reg(const StringName &name, const Reference &callback) {
    callbacks[name] = callback;
}

void ScriptTransport::send(const StringName &name, const Reference &object) {
    auto it = callbacks.find(name);
    if (it != callbacks.end()) {
        Callback *callback = (*it->second)->cast_to<Callback>();
        if (callback)
            callback->invoke(Array(vector<Variant>{{object}}));
    }
}