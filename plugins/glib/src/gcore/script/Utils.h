//
// Created by gen on 16/9/17.
//

#ifndef VOIPPROJECT_UTILS_H
#define VOIPPROJECT_UTILS_H

#include <core/Variant.h>
#include <core/Reference.h>

using namespace gc;

namespace gscript {

    template <typename T, typename>
    struct _variant_helper {
        static Variant make(T o) {
            return Variant(&o);
        }
    };

    template <typename T, typename B>
    struct _variant_helper<T, B*> {
        static Variant make(T o) {
            if (o->getInstanceClass()->isTypeOf(Reference::getClass())) {
                return Variant(o);
            }else {
                return Reference(o);
            }
        }
    };

    template <typename B>
    struct _variant_helper<int, B> {
        static Variant make(B o) {
            return Variant(o);
        }
    };
    template <typename B>
    struct _variant_helper<long, B> {
        static Variant make(B o) {
            return Variant(o);
        }
    };
    template <typename B>
    struct _variant_helper<float, B> {
        static Variant make(B o) {
            return Variant(o);
        }
    };
    template <typename B>
    struct _variant_helper<double, B> {
        static Variant make(B o) {
            return Variant(o);
        }
    };
    template <typename T>
    struct _variant_creator : public _variant_helper<typename remove_reference<typename remove_const<T>::type >::type, T> {};

    template <typename T>
    Variant var(T o) {
        return _variant_creator<T>::make(o);
    }

};

#endif //VOIPPROJECT_UTILS_H
