//
// Created by gen on 16/8/31.
//

#ifndef VOIPPROJECT_REFERENCE_H
#define VOIPPROJECT_REFERENCE_H

#include "Define.h"
#include <mutex>

namespace gc {
    class Object;
    class Class;
    class ClassDB;
    class Variant;
    class StringName;

    class Reference {
    BASE_FINAL_CLASS_DEFINE
    private:
        static Reference nullRef;

        Object *ptr;

    protected:
        void release();
        void retain();

        friend class ClassDB;
        friend class Weak;

    public:
        Reference(const Reference &other) : ptr(other.ptr) {
            retain();
        }
        _FORCE_INLINE_ Reference() : ptr(NULL) {}
        _FORCE_INLINE_ Reference(Object *p) : ptr(p) {retain();}

        _FORCE_INLINE_ ~Reference() {
            release();
        }

        void ref(const Reference *other);
        _FORCE_INLINE_ void clear() {
            release();
            ptr = NULL;
        }
        _FORCE_INLINE_ static const Reference &null() {
            return nullRef;
        }

        _FORCE_INLINE_ Reference &operator=(const Reference &other) {
            ref(&other);
            return *this;
        }
        Reference &operator=(Object *p);
        _FORCE_INLINE_ Object *operator->() {return ptr;}
        _FORCE_INLINE_ Object *operator->() const {return ptr;}

        _FORCE_INLINE_ Object &operator*() {return *ptr;}
        _FORCE_INLINE_ Object &operator*() const {return *ptr;}

        _FORCE_INLINE_ bool operator==(const Reference &other) const {
            return ptr == other.ptr;
        }
        template<class T>
        _FORCE_INLINE_ bool operator==(const T *other) const {
            return ptr == other;
        }
        _FORCE_INLINE_ bool operator!=(const Reference &other) const {
            return ptr != other.ptr;
        }
        _FORCE_INLINE_ operator Object*() const {
            return ptr;
        }
        _FORCE_INLINE_ Object* get() const {
            return ptr;
        }
        const Class *getType() const;
        _FORCE_INLINE_ operator bool() const {
            return ptr != NULL;
        }
        void call(const StringName &name, Variant *result, const Variant **params, int count);

        Reference(const Variant &other);

        std::string str() const;
    };

    class Weak {
    BASE_FINAL_CLASS_DEFINE
    private:
        static Weak nullWeak;
        std::mutex mtx;
        Reference on_delete;
        Object *ptr = NULL;

        void onDelete();

        void untouch();
        void touch();

    public:
        Weak(const Weak &other) : ptr(other.ptr) {
            std::lock_guard<std::mutex> lock(mtx);
            touch();
        }
        Weak() : ptr(NULL) {}
        Weak(Object *p) : ptr(p) {
            std::lock_guard<std::mutex> lock(mtx);
            touch();
        }
        Weak(const Reference & other) : ptr(other.ptr) {
            std::lock_guard<std::mutex> lock(mtx);
            touch();
        }
        Weak &operator=(const Weak &other) {
            std::lock_guard<std::mutex> lock(mtx);
            untouch();
            ptr = other.ptr;
            touch();
            return *this;
        }
        Weak &operator=(const Reference &other) {
            std::lock_guard<std::mutex> lock(mtx);
            untouch();
            ptr = other.ptr;
            touch();
            return *this;
        }
        Weak &operator=(Object *other) {
            std::lock_guard<std::mutex> lock(mtx);
            untouch();
            ptr = other;
            touch();
            return *this;
        }
        ~Weak() {
            untouch();
        }

        operator bool() const {
            std::lock_guard<std::mutex> lock(const_cast<Weak *>(this)->mtx);
            return !!ptr;
        }

        Object * get() const {
            std::lock_guard<std::mutex> lock(const_cast<Weak *>(this)->mtx);
            return ptr;
        }
    };
}

#endif //VOIPPROJECT_REFERENCE_H
