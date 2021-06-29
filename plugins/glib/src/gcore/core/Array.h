//
//  Vector.h
//  hirender_iOS
//
//  Created by Gen on 16/9/25.
//  Copyright © 2016年 gen. All rights reserved.
//

#ifndef Vector_h
#define Vector_h

#include "Class.h"
#include "Base.h"
#include <vector>
#include <string>
#include <unordered_map>
#include "Ref.h"
#include "Variant.h"
#include "core_define.h"

namespace gc {
    class Array;
    class Callback;

    CLASS_BEGIN_N(_Array, Object)
    
    public:
        typedef variant_vector::const_iterator Iterator;
    
    
        ENUM_BEGIN(ArrayEvent)
            Insert = 1,
            Remove,
            Replace
        ENUM_END
    
    private:
        variant_vector variants;
        void *listener;
    
        bool triger(ArrayEvent event, long idx, const Variant &v);
        bool replace(long idx, const Variant &v1, const Variant &v2);
    
        friend class Array;

    public:
    
        _FORCE_INLINE_ _Array() : listener(NULL) {}
        template<class T>
        _Array(const T &vs) : _Array() {
            for (auto it = vs.begin(), _e = vs.end(); it != _e; ++it) {
                variants.push_back(*it);
            }
        }
        ~_Array();
    
        virtual std::string str() const;
        template<class T>
        _FORCE_INLINE_ _Array &operator=(const T &vs) {
            variants.clear();
            for (auto it = vs.begin(), _e = vs.end(); it != _e; ++it) {
                variants.push_back(*it);
            }
            return *this;
        }
        _FORCE_INLINE_ _Array &operator=(const _Array &other) {
            variants = other.variants;
            return *this;
        }

        _FORCE_INLINE_ Variant &operator[](long n) {
            return variants[n];
        }
        _FORCE_INLINE_ const Variant &operator[](long n) const {
            return at(n);
        }
        METHOD _FORCE_INLINE_ long size() const {
            return variants.size();
        }
        METHOD _FORCE_INLINE_ void resize(long size)  {
            variants.resize(size);
        }
        template<class T>
        void contact(const T &other) {
            for (auto it = other.begin(), _e = other.end(); it != _e; ++it) {
                variants.push_back(*it);
            }
        }
        _FORCE_INLINE_ Iterator begin() const {
            return variants.begin();
        }
        _FORCE_INLINE_ Iterator end() const {
            return variants.end();
        }
        METHOD void push_back(const Variant &var);
        _FORCE_INLINE_ Variant &at(long n) {
            return variants.at(n);
        }
        _FORCE_INLINE_ const Variant &at(long n) const {
            return n < variants.size() ? variants.at(n) : Variant::null();
        }
        METHOD _FORCE_INLINE_ const Variant &get(long n) const {
            return at(n);
        }
        METHOD void erase(long n);
        METHOD Variant pop_back();
        METHOD void insert(long n, const Variant &var);
        METHOD void set(long idx, const Variant &var);
        METHOD void remove(const Variant &var);
        METHOD long find(const Variant &var);
        METHOD _FORCE_INLINE_ void clear() {
            variants.clear();
        }

        _FORCE_INLINE_ variant_vector &vec() {
            return variants;
        }

        METHOD Ref<_Array> copy() {
            return new _Array(variants);
        }
    
        /**
         * (ArrayEvent, long idx, Variant new_variant, Variant old_variant)
         */
        METHOD void setListener(const Callback &callback);

    protected:
        ON_LOADED_BEGIN(cls, Object)
            ADD_METHOD(cls, _Array, size);
            ADD_METHOD(cls, _Array, push_back);
            ADD_METHOD(cls, _Array, get);
            ADD_METHOD(cls, _Array, set);
            ADD_METHOD(cls, _Array, erase);
            ADD_METHOD(cls, _Array, pop_back);
            ADD_METHOD(cls, _Array, find);
            ADD_METHOD(cls, _Array, clear);
            ADD_METHOD(cls, _Array, resize);
            ADD_METHOD(cls, _Array, insert);
            ADD_METHOD(cls, _Array, copy);
        ON_LOADED_END
    CLASS_END

    class Array : public Ref<_Array> {

    public:
        _FORCE_INLINE_ Array() : Ref(new _Array(variant_vector())) {}
        _FORCE_INLINE_ Array(const variant_vector &variants) : Ref(new _Array(variants)) {
        }
        _FORCE_INLINE_ Array(std::initializer_list<variant_vector::value_type> list) : Ref(new _Array(list)) {}
        _FORCE_INLINE_ Array(const Reference &ref) : Ref(ref) {}

        _FORCE_INLINE_ const Variant &at(long n) const {
            return get()->operator[](n);
        }

        _FORCE_INLINE_ size_t size() const {
            return get() ? get()->size() : 0;
        }

        _FORCE_INLINE_ operator Variant() const {
            return Variant(*this);
        }
        Array(const Variant &var) : Array() {
            if (var && var.getTypeClass()->isTypeOf(_Array::getClass())) {
                operator=(var.ref());
            }else {
                get()->push_back(var);
            }
        }
        _FORCE_INLINE_ void contact(const Array &other) {
            if (other) {
                get()->contact(*other);
            }
        }

        _FORCE_INLINE_ Variant &operator[](long n) const {
            return get()->at(n);
        }

        _FORCE_INLINE_ variant_vector &vec() const {
            return get()->vec();
        }

        _FORCE_INLINE_ void push_back(const Variant &var) { get()->push_back(var); }
        _FORCE_INLINE_ void operator<<(const Variant &var) {push_back(var);}

        _FORCE_INLINE_ void remove(const Variant &var) { get()->remove(var); }

    CLASS_END
}


#endif /* Vector_h */
