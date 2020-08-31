//
// Created by gen on 16/9/6.
//

#ifndef VOIPPROJECT_SCRIPTCLASS_H
#define VOIPPROJECT_SCRIPTCLASS_H

#include "../Base.h"
#include "../StringName.h"
#include "../Variant.h"

#include "../core_define.h"

namespace gc {
    class Object;
    class Script;

    
    /**
     * ScriptClass 是c++和script层中class的中间件,负责转发函数调用
     * 以及创建c++对象和native对象。
     * 为了命名统一定义以下命名规则：
     * c++层 -> native
     * 中间件 -> middle
     * script-> script
     */
    CLASS_BEGIN_0_V(ScriptClass)
    private:
        const Class *cls;
        Script *script;
        void *script_cls;
        friend class Script;

    protected:
        /*
         * 重载这个方法 
         * 只需要new一个对应script的instance并返回即可。
         */
        virtual ScriptInstance *makeInstance() const = 0;

        virtual void bindScriptClass() = 0;

    public:
        _FORCE_INLINE_ ScriptClass() : cls(NULL), script(NULL) {}
        _FORCE_INLINE_ virtual ~ScriptClass() {}

        _FORCE_INLINE_ const Class *getNativeClass() const {
            return cls;
        }
        _FORCE_INLINE_ const Script *getScript() const {
            return script;
        }
        _FORCE_INLINE_ void setNativeClass(const Class *cls) {
            this->cls = cls;
        }
        _FORCE_INLINE_ void setScript(Script *script) {
            this->script = script;
        }
        _FORCE_INLINE_ void *getScriptClass() const {
            return script_cls;
        }
    
        /**
         * 在把native转换为script类型的时候应该首先把get一次middle instance
         * 如果存在那么直接通过middle instance获得script instance
         * 如果不存在，得create一个middle instance记得给script instance
         * 一个middle的引用然后给middle一个script的引用。
         * 
         * 在初始化一个注册在native中的script instance的时候
         * 使用newInstance 创建middle instance附加操作和create一致。
         */
        /**
         * 获得一个中间件，没有找到返回空(NULL)
         */
        ScriptInstance *get(Object *target) const;

        /**
         * 创建一个中间件
         */
        virtual ScriptInstance *create(Object *target) const;
    
        /**
         * 初始化一个新的ScriptInstance并且会创建对应的c++对象，
         * 通过这个方法获得的ScriptInstance持有c++对象的内存控制权。
         * 在script中创建对象时使用。
         */
        ScriptInstance *newInstance(const Variant **params, int count);

        /**
         * native -> script
         */
        virtual Variant apply(const StringName &name, const Variant **params, int count) const = 0;
        /**
         * script -> native
         */
        Variant call(const StringName &name, const Variant **params, int count) const;
    

    CLASS_END

}


#endif //VOIPPROJECT_SCRIPTCLASS_H
