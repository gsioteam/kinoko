//
// Created by gen on 16/9/6.
//

#ifndef VOIPPROJECT_JCLASS_H
#define VOIPPROJECT_JCLASS_H

#include <core/script/ScriptClass.h>
#include <jni.h>
#include "./jtools.h"
#include "../script_define.h"

using namespace gc;

namespace gscript {
    class JScript;

    class JClass : public ScriptClass {
        JClassWrap *clz;
    protected:
        virtual ScriptInstance *makeInstance() const;
        virtual void bindScriptClass();

    public:
        _FORCE_INLINE_ JClass() : clz(NULL) {}
        ~JClass();
        virtual Variant apply(const StringName &name, const Variant **params, int count) const;
        JClassWrap *getJavaClass() const {return clz;}


    };
}


#endif //VOIPPROJECT_JCLASS_H
