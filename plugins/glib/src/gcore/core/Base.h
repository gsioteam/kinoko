//
// Created by gen on 16/5/30.
//

#ifndef HICORE_OBJECT_H
#define HICORE_OBJECT_H

#include <string>
#include <iostream>
#include <iostream>
#include "Action.h"
#include "Variant.h"
#include "Class.h"
#include "Define.h"
#include "runtime.h"

/**
 * CLASS_BEGIN_0 定义一个继承自Object的类
 */
#define CLASS_BEGIN_0(NAME)     CLASS_BEGIN(NAME, __CLASS_NS(OBJECT_CLASS))
#define CLASS_BEGIN_0_N(NAME)   CLASS_BEGIN_N(NAME, __CLASS_NS(OBJECT_CLASS))
#define CLASS_BEGIN_0_NV(NAME)  CLASS_BEGIN_NV(NAME, __CLASS_NS(OBJECT_CLASS))
#define CLASS_BEGIN_0_V(NAME)   CLASS_BEGIN_V(NAME, __CLASS_NS(OBJECT_CLASS))

#define OBJECT_CLASS    Base
#define OBJECT_NAME     "Base"

namespace gc {
    class Script;
    class ScriptClass;
    class ScriptInstance;
    class Variant;

    class OBJECT_CLASS {
    private:
        friend class Variant;

    protected:
        _FORCE_INLINE_ static void onClassLoaded(Class *clz) {}
        _FORCE_INLINE_ virtual void _copy(const Object *other) {}

        friend class ClassDB;

    public:
        static const StringName KEY_INITIALIZE;

        METHOD void initialize() {}
        static const Class *getClass() {
            if (!_class_contrainer<Object>::_class) {
                const Class *clazz = ClassDB::getInstance()->find_loaded(ClassDB::connect("gc", OBJECT_NAME));
                _class_contrainer<Object>::_class = clazz ? clazz : ClassDB::getInstance()->cl<OBJECT_CLASS>("gc", OBJECT_NAME, NULL);
            }
            return _class_contrainer<Object>::_class;
        }

        _FORCE_INLINE_ virtual const Class *getInstanceClass() const {
            return Base::getClass();
        }

        _FORCE_INLINE_ bool instanceOf(const Class *clz) const {
            const Class *cClz = getInstanceClass();
            while (cClz) {
                if (cClz == clz) return true;
                cClz = cClz->getParent();
            }
            return false;
        }
        void call(const StringName &name, Variant *result, const Variant **params = NULL, int count = 0);

        virtual void missMethod(const StringName &name, Variant *result, const Variant **params, int count) {}
        
        Variant call(const StringName &name, const pointer_vector &params = pointer_vector()) {
            Variant ret;
            call(name, &ret, (const Variant **)params.data(), (int)params.size());
            return ret;
        }
        template<typename ...ARGS>
        Variant callArgs(const StringName &name, ARGS &&...args) {
            const int size = sizeof...(ARGS);
            Variant ret;
            if (size) {
                variant_vector vs{{args...}};
                pointer_vector pv;
                for (int i = 0; i < size; ++i) {
                    pv.push_back(&vs[i]);
                }
                call(name, &ret, (const Variant **)pv.data(), (int)pv.size());
            }else {
                call(name, &ret);
            }
            return ret;
        }
        
        template<class T>
        _FORCE_INLINE_ T *cast_to() {
            return this ? (getInstanceClass()->isTypeOf(T::getClass()) ? static_cast<T*>(this) : NULL) : NULL;
        }
        template<class T>
        _FORCE_INLINE_ const T *cast_to() const {
            return this ? (getInstanceClass()->isTypeOf(T::getClass()) ? static_cast<const T*>(this) : NULL) : NULL;
        }

        _FORCE_INLINE_ virtual std::string str() const {
            const Class *cls = getInstanceClass();
            return "[" + std::string(cls->getFullname().str()) + "]";
        }
        Variant var();

        bool copy(const Object *other);

//        bool test_object;
    };
}


#endif //HICORE_OBJECT_H
