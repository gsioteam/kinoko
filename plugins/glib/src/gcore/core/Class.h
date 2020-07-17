//
// Created by gen on 16/5/30.
//

#ifndef HICORE_CLASS_H
#define HICORE_CLASS_H

#include <string>
#include <map>
#include <list>
#include <mutex>
#include "Hash.h"
#include "StringName.h"

#include "Variant.h"

#include "Define.h"

namespace gc  {
    class Base;
    class ClassDB;
    class Method;
    class Property;
    class StringName;

    typedef void * object_type;

    class Class {
    private:
        const char *ns;
        const char *name;
        StringName *fullname;
        const Class *parent;
        pointer_map methods;
        pointer_map properties;
        const Method *initializer;

        variant_map labels;

        friend class ClassDB;

    protected:
        size_t size;
        Class() : ns(NULL), parent(NULL), initializer(NULL) {}
        Class(const char *ns, const char *name);
    public:
        ~Class();

        /**
         * Get the class name
         */
        _FORCE_INLINE_ const char *getName() const {
            return name;
        }

        /**
         * Get the namespace of class
         */
        _FORCE_INLINE_ const char *getNS() const {
            return ns;
        }

        /**
         * Fullname namespace::name
         */
        _FORCE_INLINE_ const StringName &getFullname() const {
            return *fullname;
        }

        /**
         * Get parent class
         */
        _FORCE_INLINE_ const Class *getParent() const {
            return  parent;
        }
        /**
         * Make a new instance from class via T()
         */
        virtual object_type instance() const {return NULL;};

        /**
         * The size of target
         */
        _FORCE_INLINE_ size_t getSize() const {
            return size;
        }
        
        /**
         * Check if this class is the subclass of the other class.
         */
        _FORCE_INLINE_ bool isSubclassOf(const Class *cls) const {
            const Class *p = getParent();
            while (p) {
                if (p == cls) return true;
                p = p->getParent();
            }
            return false;
        }

        _FORCE_INLINE_ bool isTypeOf(const Class *cls) const {
            return this == cls || isSubclassOf(cls);
        }
        _FORCE_INLINE_ virtual void del(void *object) const {}

        const Method *addMethod(const Method *method);

        _FORCE_INLINE_ const Method *getMethod(const StringName &name) const {
            auto it = methods.find(name);
            return it == methods.end() ? NULL:(const Method *)it->second;
        }
        _FORCE_INLINE_ const void setInitializer(const Method *method) {
            initializer = method;
        }
        _FORCE_INLINE_ const Method *getInitializer() const {
            return initializer;
        }

        const Property *addProperty(const Property *property);
        const Property *getProperty(const StringName &name) const {
            auto it = properties.find(name);
            return it == properties.end() ? NULL:(const Property *)it->second;
        }

        const pointer_map &getMethods() const;
        const pointer_map &getProperties() const;

        void setLabels(const variant_map &labels);
        _FORCE_INLINE_ bool hasLabel(const StringName &name) const {
            return labels.find(name) != labels.end();
        }
        _FORCE_INLINE_ const Variant &getLabel(const StringName &name) const {
            auto it = labels.find(name);
            return it == labels.end() ? Variant::null() : it->second;
        }

        Variant call(const StringName &name, object_type obj, const Variant **params, int count) const;
    };
    
    
    template<class T>
    struct _class_contrainer {
        static const Class *_class;
    };
    template<class T>
    const Class * _class_contrainer<T>::_class = NULL;

    class ClassDB {
    public:
        typedef const Class *(ClassLoader)();

    private:
        static ClassDB *instance;
        static std::mutex mtx;

        template<class T>
        class VirtualClass : Class {
        private:
            friend class ClassDB;
            _FORCE_INLINE_ VirtualClass(const char *ns, const char *name) : Class(ns, name) {
                size = sizeof(T);
            }
        public:
            _FORCE_INLINE_ virtual void del(void *object) const {
                delete (T*)object;
            }
            virtual object_type instance() const {return NULL;};
        };

        template<class T>
        class TypeClass : VirtualClass<T> {
        private:
            friend class ClassDB;
            _FORCE_INLINE_ TypeClass(const char *ns, const char *name) : VirtualClass<T>(ns, name) {}

        public:
            _FORCE_INLINE_ virtual void del(void *object) const {
                delete (T*)object;
            }
            _FORCE_INLINE_ virtual object_type instance() const {return new T();};
        };

        pointer_map     classes_index;
        pointer_list    classes;
        pointer_map     class_loaders;

        template<class T>
        const Class *_vcls(const char *ns, const char *name, const Class *super) {
            void* hash = ns ? h(std::string(ns) + "::" + name) : h(name);
            auto ite = classes_index.find(hash);

            if (ite == classes_index.end()) {
                Class *clz = new VirtualClass<T>(ns, name);
                classes_index[hash] = clz;
                classes.push_back(clz);
                clz->parent = super;
                T::onClassLoaded(clz);
                return clz;
            }else
                return (const Class *) (*ite).second;
        }

        template<class T>
        const Class *_cls(const char *ns, const char *name, const Class *super) {
            void *hash = ns ? h(std::string(ns) + "::" + name) : h(name);
            auto ite = classes_index.find(hash);
            if (ite == classes_index.end()) {
                Class *clz = (Class*)new TypeClass<T>(ns, name);
                classes_index[hash] = clz;
                classes.push_back(clz);
                clz->parent = super;
                T::onClassLoaded(clz);
                return clz;
            }else
                return (const Class *) (*ite).second;
        }

        void loadClasses();

    public:
        _FORCE_INLINE_ ClassDB(){}
        _FORCE_INLINE_ ~ClassDB() {
            for (auto ite = classes.begin(); ite != classes.end(); ++ite) {
                delete((Class*)*ite);
            }
        }

        _FORCE_INLINE_ static ClassDB *getInstance() {
            bool init = false;
            mtx.lock();
            if (!instance) {
                instance = new ClassDB;
                init = true;
            }
            mtx.unlock();
            if (init) {
                instance->loadClasses();
            }
            return instance;
        }

        _FORCE_INLINE_ static void reg(const StringName &name, ClassLoader loader) {
            getInstance()->class_loaders[name] = (void*)loader;
        }
        template <class T>
        static void reg() {
            getInstance()->class_loaders[T::getClassName()] = (void*)&T::getClass;
        }

        const Class * find_loaded(const StringName &fullname);
        const Class * find(const StringName &fullname);

        _FORCE_INLINE_ static StringName connect(const char *ns, const char *name) {
            return StringName(ns? (std::string(ns) + "::" + name).c_str() : name);
        }
        
        /**
         * Register or get a class
         */
        template<class Tc>
        _FORCE_INLINE_ const Class *cl(const char *ns, const char *name, const Class *super = NULL)
        {return _cls<Tc>(ns, name, super);}
        template<class Tc>
        _FORCE_INLINE_ const Class *vr(const char *ns, const char *name, const Class *super = NULL)
        {return _vcls<Tc>(ns, name, super);}
        

    };

}

#endif //HICORE_CLASS_H
