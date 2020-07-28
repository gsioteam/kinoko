//
// Created by gen on 16/5/30.
//

#ifndef HICORE_VARIANT_H
#define HICORE_VARIANT_H

#include <cstdlib>
#include <string>
#include "Define.h"
#include "Reference.h"
#include "StringName.h"

#include "core_define.h"

namespace gc {

    template<class T>
    class Ref;
    class Base;

    class Variant {
        BASE_FINAL_CLASS_DEFINE
    public:

        ENUM_BEGIN(Type)
            TypeNull = 0,
            TypeBool,
            TypeChar,
            TypeShort,
            TypeInt,
            TypeLong,
            TypeLongLong,
            TypeFloat,
            TypeDouble,
            TypePointer,
            TypeStringName,
            TypeMemory,
            TypeObject,
            TypeReference,
        ENUM_END

        typedef union {
            bool    v_bool;
            char    v_char;
            short   v_short;
            int     v_int;
            long    v_long;
            long    v_longlong;
            float   v_float;
            double  v_double;
            void*   v_pointer;
        } u_value;

    private:

        u_value value;
        int8_t type = TypeNull;
        const Class *class_type;

        void release();
        void retain(const u_value &value, const Class *class_type, int8_t type = -1);
        static bool isRef(int8_t type);

        
        template<class T = Base>
        _FORCE_INLINE_ T *_get() const {
            return value.v_pointer;
        }
        
        static const Variant _null;

    public:

        _FORCE_INLINE_ static const Variant &null() {return _null;}

        _FORCE_INLINE_ Variant(void) : type(TypeNull) {
            value.v_pointer = NULL;
        }

        Variant(Variant &&other) {
            std::swap(value, other.value);
            std::swap(type, other.type);
            std::swap(class_type, other.class_type);
        }

        Variant(const Variant &other) : Variant() {
            retain(other.value, other.class_type, other.type);
        }

        
        _FORCE_INLINE_ Variant(const Reference &referene) : Variant() {
            if (referene) retain(u_value{v_pointer:referene.get()}, referene.getType(), TypeReference);
        }

        _FORCE_INLINE_ ~Variant() {
            release();
        }
        
        template<class T = Base>
        _FORCE_INLINE_ T *get() const {
            return (T*)operator void *();
        }
        template<>
        _FORCE_INLINE_ const char *get() const {
            return operator const char *();
        }
        template <class T>
        _FORCE_INLINE_ void getMemory(T &var) const {
            if (type == TypeMemory && T::getClass() == class_type) {
                var = *(T*)value.v_pointer;
            }
        }

        template <typename T>
        static Variant memoryVar(const T *target) {
            Variant v;
            v.retain(u_value{v_pointer: (void*)target}, T::getClass(), TypeMemory);
            return v;
        }

//        void operator=(const HObject *object);
        void operator=(const Variant &other) {
            release();
            retain(other.value, other.class_type, other.type);
        }

        bool operator==(const Variant &other) const;

        _FORCE_INLINE_ Base *operator->() const {
            return get();
        }

        const Class *getTypeClass() const;
        Type getType() const;

        _FORCE_INLINE_ Reference ref() const {
            return isRef() ? Reference((Object*)value.v_pointer) : Reference();
        }

        _FORCE_INLINE_ bool isRef() const { return isRef(type); }
        _FORCE_INLINE_ bool empty() const { return type == TypeNull || (type >= TypePointer && value.v_pointer == NULL); }


        operator bool() const;
        operator char() const;
        operator signed char() const;
        operator unsigned char() const;
        operator short() const;
        operator unsigned short() const;
        operator int() const;
        operator unsigned int() const;
        operator long() const;
        operator unsigned long() const;
        operator long long() const;
        operator unsigned long long() const;
        operator float() const;
        operator double() const;

        operator std::string() const;
        
        operator void *() const;
        operator const char *() const;
        operator Base *() const;
        operator StringName() const;

        std::string str() const;
        
        Variant(char);
        Variant(short);
        Variant(int);
        Variant(long);
        Variant(long long);

        Variant(unsigned char);
        Variant(unsigned short);
        Variant(unsigned int);
        Variant(unsigned long);
        Variant(unsigned long long);

        Variant(float);
        Variant(double);
        Variant(bool);
        Variant(const std::string &);
        Variant(const char *);
        Variant(const Base*);
        Variant(void*);
        Variant(const StringName &name);

        template <class T>
        static Variant make(T v) {
            return Variant(&v);
        }

    };

}


#endif //HICORE_VARIANT_H
