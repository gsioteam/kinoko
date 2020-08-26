//
// Created by gen on 16/7/5.
//

#ifndef HI_RENDER_PROJECT_ANDROID_SCRIPT_H
#define HI_RENDER_PROJECT_ANDROID_SCRIPT_H

#include <string>
#include <map>
#include <set>
#include "../Define.h"
#include "../Action.h"
#include "../StringName.h"

namespace gc {
    class Class;
    class Script;
    class ScriptClass;
    class ScriptInstance;
    class Object;
    class Variant;

    /**
     * Script 用于对应不同的script，每个script同时只存在一个Script对象
     * Script对象会管理ScriptClass
     * ScriptClass对象可以使用find和get来管理。
     */
    class Script {
        
        static pointer_set scripts;
        pointer_map classes;
        pointer_set instances;
        StringName name;

        void addInstance(ScriptInstance *ins);
        void removeInstance(ScriptInstance *ins);
        friend class ScriptInstance;
        friend class ScriptClass;

    protected:
        /**
         * Need override
         *
         * To make a special class
         */
        virtual ScriptClass *makeClass() const = 0;

//        virtual void defineFunction(const StringName &name, const Callback &function) = 0;
        /**
         * 当create是true的时候表明返回值是刚创建出来的
         * 这是需要做一些初始化操作,其中必须建立脚本类与中间
         * 类的联系
         */
        ScriptClass *findOrCreate(const StringName &fullname, bool &create);

        void clear();

    public:
        virtual ~Script();

        /**
         * 查找中间类
         */
        ScriptClass *find(const StringName &fullname) const;
        ScriptClass *find(const Class *cls) const;

        ScriptClass *regClass(void *script_cls, const gc::StringName &name);
        Script(const StringName &name);
        
        static Script *get(const StringName &name);
        
        ScriptInstance *getScriptInstance(const Object *target) const;
//        /**
//         * 查找一个script环境中的类.并创建一个script对象.
//         * 这时script instance不拥有target的内存控制权.
//         */
//        virtual ScriptInstance *newBuff(const std::string &cls_name, Object *target, const Variant **params, int count) const = 0;

//        void addFunction(const StringName &name, const Callback &function);

        virtual gc::Variant runScript(const char *script, const char *filename = nullptr) const = 0;
        virtual gc::Variant runFile(const char *filepath) const;

        const StringName &getName() const {
            return name;
        }
    };
}


#endif //HI_RENDER_PROJECT_ANDROID_SCRIPT_H
