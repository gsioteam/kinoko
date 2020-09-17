
#include <core/script/Script.h>
#include <core/script/ScriptClass.h>
#include <core/script/ScriptInstance.h>
#include "../script_define.h"

namespace gscript {
    class JSCoreItem;

    CLASS_BEGIN_N(JSCoreClass, gc::ScriptClass)

        virtual gc::ScriptInstance *makeInstance() const;

        virtual void bindScriptClass();
    public:

        virtual gc::Variant apply(const gc::StringName &name, const gc::Variant **params, int count) const;

        ~JSCoreClass();

    CLASS_END

    CLASS_BEGIN_N(JSCoreInstance, gc::ScriptInstance)
    
        JSCoreItem *value = nullptr;
    
    public:

        ~JSCoreInstance();

        void setValue(JSCoreItem *v) { value = v; }
        JSCoreItem *getValue() const { return value; }

        virtual gc::Variant apply(const gc::StringName &name, const gc::Variant **params, int count);

    CLASS_END

    class JSCoreScript : public gc::Script {
        void *context = nullptr;

    protected:
        virtual gc::ScriptClass *makeClass() const;
        
    public:
        
        JSCoreScript(const char *dir);
        ~JSCoreScript();
        
        void *getContext() const {
            return context;
        }
        
        virtual gc::ScriptInstance *newBuff(const std::string &cls_name, gc::Object *target, const gc::Variant **params, int count) const;

        virtual gc::Variant runFile(const char *filepath) const;
        virtual gc::Variant runScript(const char *script, const char *filename = nullptr) const;
        
    };

}
