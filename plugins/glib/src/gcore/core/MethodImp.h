//
// Created by gen on 16/8/31.
//

#ifndef VOIPPROJECT_METHODIMP_H
#define VOIPPROJECT_METHODIMP_H

#include "Method.h"
#include "Class.h"
#include "core_define.h"

namespace gc {

    class Base;
    
    
    template<int... Is>
    struct seq { };
    
    template<int N, int... Is>
    struct gen_seq : gen_seq<N - 1, N - 1, Is...> { };
    
    template<int... Is>
    struct gen_seq<0, Is...> : seq<Is...> { };
    
    template <typename _T> struct type_convert {
        _FORCE_INLINE_ static typename std::remove_reference<typename std::remove_const<_T>::type>::type toType(const Variant &v) { return v; }
        _FORCE_INLINE_ static Variant toVariant(_T v) { return v; }
    };
    template <class _T> struct type_convert<_T*> {
        _FORCE_INLINE_ static _T *toType(const Variant &v) { return v.get<_T>(); }
        _FORCE_INLINE_ static Variant toVariant(_T *v) { return v; }
    };
    template <class _T> struct type_convert<_T* const> {
        _FORCE_INLINE_ static _T *toType(const Variant &v) { return v.get<_T>(); }
        _FORCE_INLINE_ static Variant toVariant(_T * const v) { return v; }
    };
    template <class _T> struct type_convert<_T* volatile> {
        _FORCE_INLINE_ static _T *toType(const Variant &v) { return v.get<_T>(); }
        _FORCE_INLINE_ static Variant toVariant(_T * volatile v) { return v; }
    };
    template <class _T> struct type_convert<_T* const volatile> {
        _FORCE_INLINE_ static _T *toType(const Variant &v) { return v.get<_T>(); }
        _FORCE_INLINE_ static Variant toVariant(_T * const volatile v) { return v; }
    };
    
    template <class ...T_> struct base_type {};
    template <class T_, class C> struct base_type<T_, C> {
        _FORCE_INLINE_ static const Class *getClass() {
            return std::remove_pointer<typename std::remove_reference<T_>::type>::type::getClass();
        }
    };
    template <class C> struct base_type<short, C> {
        _FORCE_INLINE_ static const Class *getClass() {
            static const StringName name("gc::Short");
            return ClassDB::getInstance()->find(name);
        }
    };
    template <class C> struct base_type<unsigned short, C> {
        _FORCE_INLINE_ static const Class *getClass() {
            static const StringName name("gc::Short");
            return ClassDB::getInstance()->find(name);
        }
    };
    template <class C> struct base_type<int, C> {
        _FORCE_INLINE_ static const Class *getClass() {
            static const StringName name("gc::Integer");
            return ClassDB::getInstance()->find(name);
        }
    };
    template <class C> struct base_type<void, C> {
        _FORCE_INLINE_ static const Class *getClass() {
            return NULL;
        }
    };
    template <class C> struct base_type<const std::string &, C> {
        static const Class *getClass() {
            static const StringName name("gc::String");
            return ClassDB::getInstance()->find(name);
        }
    };
    template <class C> struct base_type<std::string, C> {
        _FORCE_INLINE_ static const Class *getClass() {
            static const StringName name("gc::String");
            return ClassDB::getInstance()->find(name);
        }
    };
    template <class C> struct base_type<const char *, C> {
        _FORCE_INLINE_ static const Class *getClass() {
            static const StringName name("gc::String");
            return ClassDB::getInstance()->find(name);
        }
    };
    template <class C> struct base_type<float, C> {
        _FORCE_INLINE_ static const Class *getClass() {
            static const StringName name("gc::Float");
            return ClassDB::getInstance()->find(name);
        }
    };
    template <class C> struct base_type<double, C> {
        _FORCE_INLINE_ static const Class *getClass() {
            static const StringName name("gc::Double");
            return ClassDB::getInstance()->find(name);
        }
    };
    template <class C> struct base_type<long, C> {
        _FORCE_INLINE_ static const Class *getClass() {
            static const StringName name("gc::Long");
            return ClassDB::getInstance()->find(name);
        }
    };
    template <class C> struct base_type<bool, C> {
        _FORCE_INLINE_ static const Class *getClass() {
            static const StringName name("gc::Boolean");
            return ClassDB::getInstance()->find(name);
        }
    };
    template <class T_> struct get_type : base_type<T_, T_> {};

    template <class T, typename M>
    static Method *MethodImp_makeMethod(const std::string &name, M method, const std::vector<Variant> &dvs);
    template <class T, typename M> static Method *MethodImp_makeMethod(const std::string &name, M method);

    template <class T, typename M, typename Ret, typename... Args>
    CLASS_BEGIN_N(MethodImp, Method)

    public:
        typedef M method_type;

    private:

        template <typename F>
        struct caller
        {};

        template <typename R_, typename... A_>
        struct caller<R_(A_...)> {
            _FORCE_INLINE_ static Variant call(void *obj, M method, A_ && ...args) {
                T* t = (T*)(obj);
                return Variant((*t.*method)(args...));
            }
        };
        template <typename... A_>
        struct caller<void(A_...)> {
            _FORCE_INLINE_ static Variant call(void *obj, M method, A_ && ...args) {
                T* t = (T*)(obj);
                (*t.*method)(args...);
                return Variant::null();
            }
        };

        method_type method;

        _FORCE_INLINE_ Variant call(void *obj, Args&& ...args) const {
            return caller<Ret(Args...)>::call(obj, method, std::forward<Args>(args)...);
        }
        template <int... Is>
        _FORCE_INLINE_ Variant _call(void *obj, const Variant **params, seq<Is...>*) const {
            return call(obj, type_convert<typename std::tuple_element<Is, std::tuple<Args...> >::type >::toType(*params[Is])...);
//            return call(obj, (*params[Is])...);
        }

        _FORCE_INLINE_ void makeParamsTypes() {
//            setParamsType((const HClass *[]){get_type<Args>::getClass()...}, sizeof...(Args));
            setParamsType(NULL, sizeof...(Args));
        }

        friend Method *MethodImp_makeMethod<T, M>(const std::string &name, M method);

    public:
        _FORCE_INLINE_ MethodImp() : Method("") {}
        MethodImp(const char *name,
                  const method_type &method,
                  bool is_const,
                  const Variant *dv = NULL,
                  int count = 0) : Method(name), method(method) {
            setType(is_const ? ConstMb : Member);
//            setReturnType(get_type<Ret>::getClass());
            makeParamsTypes();
            setDefaultValues(dv, count);
        }
        MethodImp(const char *name,
                  const method_type &method,
                  bool is_const,
                  const variant_map &labels,
                  const Variant *dv = NULL,
                  int count = 0) : Method(name), method(method) {
            setType(is_const ? ConstMb : Member);
//            setReturnType(get_type<Ret>::getClass());
            makeParamsTypes();
            setDefaultValues(dv, count);
            setLabels(labels);
        }

        _FORCE_INLINE_ virtual Variant _call(void *obj, const Variant **params) const {
            gen_seq<sizeof...(Args)> d;
            return _call(obj, params, &d);
        }

    CLASS_END

    template <class T, typename M, typename Ret, typename... Args>
    CLASS_BEGIN_N(StaticMethodImp, Method)

    public:
        typedef M method_type;

    private:
        method_type method;
    
        template <typename F>
        struct caller
        {};
    
        template <typename R_, typename... A_>
        struct caller<R_(A_...)> {
            _FORCE_INLINE_ static Variant call(M method, A_ && ...args) {
                return (*method)(args...);
            }
        };
        template <typename... A_>
        struct caller<void(A_...)> {
            _FORCE_INLINE_ static Variant call(M method, A_ && ...args) {
                (*method)(args...);
                return Variant::null();
            }
        };
        _FORCE_INLINE_ Variant call(Args&& ...args) const {
            return caller<Ret(Args...)>::call(method, std::forward<Args>(args)...);
        }
    
        template <int... Is>
        _FORCE_INLINE_ Variant _call(const Variant **params, seq<Is...>*) const {
            return call(type_convert<typename std::tuple_element<Is, std::tuple<Args...> >::type >::toType(*params[Is])...);
        }

        void makeParamsTypes() {
//            setParamsType((const HClass *[]){get_type<Args>::getClass()...}, sizeof...(Args));
            setParamsType(NULL, sizeof...(Args));
        }

        friend Method *MethodImp_makeMethod<T, M>(const std::string &name, M method);

public:
    _FORCE_INLINE_ StaticMethodImp() : Method("") {}
    StaticMethodImp(const char *name,
                    const method_type &method,
                    const Variant *dv = NULL,
                    int count = 0) : Method(name), method(method) {
        setType(Static);
//        setReturnType(get_type<Ret>::getClass());
        makeParamsTypes();
        setDefaultValues(dv, count);
    }
    StaticMethodImp(const char *name,
                    const method_type &method,
                    const variant_map &labels,
                    const Variant *dv = NULL,
                    int count = 0) : Method(name), method(method) {
        setType(Static);
//        setReturnType(get_type<Ret>::getClass());
        makeParamsTypes();
        setDefaultValues(dv, 0);
        setLabels(labels);
    }

        _FORCE_INLINE_ virtual Variant _call(void *obj, const Variant **params) const {
            gen_seq<sizeof...(Args)> d;
            return _call(params, &d);
        }

    CLASS_END

    template <typename T>
    struct function_traits : public function_traits<decltype(T())>
    {};

    template <typename ClassType, typename ReturnType, typename... Args>
    struct function_traits<ReturnType(ClassType::*)(Args...)>
    {
        template <class T, class M>
        _FORCE_INLINE_ static Method *makeMethod(const char *name, M method, const variant_vector &dvs) {
            return new MethodImp<T, M, ReturnType, Args...>(name, method, false, dvs.data(), dvs.size());
        }
        template <class T, class M>
        _FORCE_INLINE_ static Method *makeMethod(const char *name, M method) {
            return new MethodImp<T, M, ReturnType, Args...>(name, method, false);
        }
    };
    template <typename ReturnType, typename... Args>
    struct function_traits<ReturnType(*)(Args...)>
    {
        template <class T, class M>
        _FORCE_INLINE_ static Method *makeMethod(const char *name, M method, const variant_vector &dvs) {
            return new StaticMethodImp<T, M, ReturnType, Args...>(name, method, dvs.data(), dvs.size());
        }
        template <class T, class M>
        _FORCE_INLINE_ static Method *makeMethod(const char *name, M method) {
            return new StaticMethodImp<T, M, ReturnType, Args...>(name, method);
        }
    };
    template <typename ClassType, typename ReturnType, typename... Args>
    struct function_traits<ReturnType(ClassType::*)(Args...) const> {
        template<class T, class M>
        _FORCE_INLINE_ static Method *makeMethod(const char *name, M method, const variant_vector &dvs) {
            return new MethodImp<T, M, ReturnType, Args...>(name, method, true, dvs.data(), dvs.size());
        }

        template<class T, class M>
        _FORCE_INLINE_ static Method *makeMethod(const char *name, M method) {
            return new MethodImp<T, M, ReturnType, Args...>(name, method, true);
        }
    };

    template <class T, typename M>
    _FORCE_INLINE_ static Method *MethodImp_makeMethod(const char *name, M method, const std::vector<Variant> &dvs) {
        return function_traits<M>::template makeMethod<T>(name, method, dvs);
    }
    template <class T, typename M>
    _FORCE_INLINE_ static Method *MethodImp_makeMethod(const char *name, M method) {
        return function_traits<M>::template makeMethod<T>(name, method);
    }
}

#endif //VOIPPROJECT_METHODIMP_H
