//
// Created by gen on 16/5/30.
//

#ifndef HICORE_REFERENCE_H
#define HICORE_REFERENCE_H

#include <memory>
#include "Base.h"
#include "./Reference.h"
#include "./Variant.h"
#include "./core_define.h"

namespace gc {

    template<class T>
    class Ref;
    class Reference;
    class Callback;

    CLASS_BEGIN_0_N(Object)
    private:

        struct Scripts;
        friend class Script;

        int count = 0;
        Scripts *scripts_container = NULL;
        EventManager  *event_manager = NULL;
        void _trigger(const StringName &name, const variant_vector &params);

    protected:

    public:

        const static StringName EVENT_DESTROY;

        virtual ~Object();


#ifdef USING_SCRIPT
        virtual void apply(const StringName &name, Variant *result = NULL, const Variant **params = NULL, int count = 0);
#else
        _FORCE_INLINE_ void apply(const StringName &name, Variant *result = NULL, const Variant **params = NULL, int count = 0) {}
#endif
        Variant apply(const StringName &name, const pointer_vector &params) {
            Variant ret;
            apply(name, &ret, (const Variant **)params.data(), (int)params.size());
            return ret;
        }
        template <class ...Argv>
        Variant applyArgv(const StringName &name, Argv... argv) {
            variant_vector var{argv...};
            pointer_vector pv;
            for (auto it = var.begin(), _e = var.end(); it != _e; ++it) {
                pv.push_back(&*it);
            }
            return apply(name, pv);
        }

        void addScript(ScriptInstance *scriptClass);
        void removeScript(ScriptInstance *instance);
        void clearScripts();
        ScriptInstance *findScript(const StringName &name);
        ScriptInstance *findScript(const Script *script);

        _FORCE_INLINE_ virtual int retain() {return ++count;}
        _FORCE_INLINE_ virtual int release() {return --count;}
        _FORCE_INLINE_ Object() : count(0) {}

        void on(const StringName &name, const Callback &callback);
        void off(const StringName &name, const Callback &callback);
        template <class ...Args>
        void trigger(const StringName &name, Args && ...args) {
            _trigger(name, variant_vector{{args...}});
        }

    CLASS_END

    template <class T>
    class Ref : public Reference {
    private:
        _FORCE_INLINE_ bool checkType(const Class *cls) {
            return cls && (cls == T::getClass() || cls->isSubclassOf(T::getClass()));
        }

    public:

        _FORCE_INLINE_ Ref() : Ref(NULL) {}

        Ref(T *p) {
            if (p && checkType(p->getInstanceClass())) {
                operator=(p);
            }
        }

        _FORCE_INLINE_ Ref(const Reference &other) {
            if (other && checkType(other->getInstanceClass())) {
                operator=((T*)other.get());
            }
        }

        _FORCE_INLINE_ Ref &operator=(T *p) {
            Reference::operator=((Object *) p);
            return *this;
        }

        _FORCE_INLINE_ T &operator*() { return *static_cast<T *>(get()); }

        _FORCE_INLINE_ T &
        operator*() const { return *static_cast<T *>(const_cast<Ref *>(this)->get()); }

        _FORCE_INLINE_ T *operator->() {
            return get();
        }

        _FORCE_INLINE_ T *operator->() const {
            return get();
        }
        T *get() const {
            return (T *)Reference::get();
        }

        _FORCE_INLINE_ Ref(const Variant &other) : Reference(other) {
        }
    };

    template <class T>
    class Wk : public Weak {

    private:
        _FORCE_INLINE_ bool checkType(const Class *cls) {
            return cls && (cls == T::getClass() || cls->isSubclassOf(T::getClass()));
        }

    public:

        _FORCE_INLINE_ Wk() : Wk(NULL) {}
        _FORCE_INLINE_ Wk(T *p) {
            if (p && checkType(p->getInstanceClass())) {
                operator=(p);
            }
        }
        _FORCE_INLINE_ Wk(const Weak &other) {
            if (other && checkType(other.get()->getInstanceClass())) {
                operator=((T*)other.get());
            }
        }

        Ref<T> lock() const {
            return Ref<T>(get());
        }

        T *get() const {
            return (T *)Weak::get();
        }
    };
}

#endif //HICORE_REFERENCE_H
