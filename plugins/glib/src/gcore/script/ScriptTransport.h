//
//  ScriptTransport.hpp
//  hirender_iOS
//
//  Created by Gen on 16/10/5.
//  Copyright © 2016年 gen. All rights reserved.
//

#ifndef ScriptTransport_hpp
#define ScriptTransport_hpp

#include <core/Base.h>
#include <core/Reference.h>
#include <core/StringName.h>
#include "script_define.h"

using namespace gc;

namespace gscript {
    CLASS_BEGIN_0_N(ScriptTransport)
    
private:
    static ref_map callbacks;
    
public:
    METHOD static void reg(const StringName &name, const Reference &callback);
    METHOD static void send(const StringName &name, const Reference &object);
    
    protected:
        ON_LOADED_BEGIN(cls, HObject)
            ADD_METHOD(cls, ScriptTransport, reg);
            ADD_METHOD(cls, ScriptTransport, send);
        ON_LOADED_END
    CLASS_END
}

#endif /* ScriptTransport_hpp */
