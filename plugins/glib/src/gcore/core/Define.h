//
// Created by gen on 16/5/30.
//

#ifndef gc_DEFINE_H
#define gc_DEFINE_H

#ifndef NULL
#   define NULL 0
#endif

#ifndef _ALWAYS_INLINE_

#if defined(__GNUC__) && (__GNUC__ >= 4 )
#   define _ALWAYS_INLINE_ __attribute__((always_inline)) inline
#elif defined(__llvm__)
#   define _ALWAYS_INLINE_ __attribute__((always_inline)) inline
#elif defined(_MSC_VER)
#   define _ALWAYS_INLINE_ __forceinline
#else
#   define _ALWAYS_INLINE_ inline
#endif

#endif

#ifndef _FORCE_INLINE_

#ifdef DEBUG
#   define _FORCE_INLINE_ inline
#else
#   define _FORCE_INLINE_ _ALWAYS_INLINE_
#endif

#endif

#define IV(obj, method) if (obj) obj->method;

// Object

#define new_c(CLASS, T, ...) ({ \
    T* ins = (T*)CLASS->instance();\
    ins->initialize(__VA_ARGS__);\
    ins;\
})

#define new_t(T, ...) ({\
    T* ins = new T();\
    ins->initialize(__VA_ARGS__);\
    ins;\
})

// -----

#define __CLASS_BEGIN_NS_EX(NAME, SUPER, METHOD, T) \
class NAME : public SUPER T { \
    public: \
        DEFINE_GET_CLASS_NS(__NAMESPACE__, NAME, SUPER T, METHOD) \
    private:\
        friend class __CLASS_NS(ClassDB);

#define __CLASS_BEGIN_EX(NAME, SUPER, METHOD, T) \
class NAME : public SUPER T { \
    public: \
        DEFINE_GET_CLASS(NAME, SUPER, METHOD) \
    private:\
        friend class __CLASS_NS(ClassDB);

/**
 * CLASS_BEGIN 定义一个类,
 * 带N后缀的会使用 __NAMESPACE__ 定义的值作为名称空间.
 * 带V后缀表示这是一个虚类不提供构造instance的接口,对于模版类也请加上V后缀。
 *
 * NAME 类名
 * SUPER 是父类
 */
#define CLASS_BEGIN(NAME, SUPER)    __CLASS_BEGIN_EX(NAME, SUPER, cl, _TC0())
#define CLASS_BEGIN_N(NAME, SUPER)  __CLASS_BEGIN_NS_EX(NAME, SUPER, cl, _TC0())
#define CLASS_BEGIN_NV(NAME, SUPER) __CLASS_BEGIN_NS_EX(NAME, SUPER, vr, _TC0())
#define CLASS_BEGIN_V(NAME, SUPER)  __CLASS_BEGIN_EX(NAME, SUPER, vr, _TC0())

#define __CLASS_NS(CLASS) gc::CLASS

/**
 * CLASS_BEGIN_T 用来定义一个类,
 * 这个类继承自一个带模版参数的类,
 * C最多为5,多写一些_TC能支持更多
 */
#define CLASS_BEGIN_T(NAME, SUPER, C, ...)      __CLASS_BEGIN_EX(NAME, SUPER, cl, _TC##C(__VA_ARGS__))
#define CLASS_BEGIN_TN(NAME, SUPER, C, ...)     __CLASS_BEGIN_NS_EX(NAME, SUPER, cl, _TC##C(__VA_ARGS__))
#define CLASS_BEGIN_TNV(NAME, SUPER, C, ...)    __CLASS_BEGIN_NS_EX(NAME, SUPER, vr, _TC##C(__VA_ARGS__))
#define CLASS_BEGIN_TV(NAME, SUPER, C, ...)     __CLASS_BEGIN_EX(NAME, SUPER, vr, _TC##C(__VA_ARGS__))
#define _TC0()
#define _TC1(T1)        <T1>
#define _TC2(T1, T2)        <T1, T2>
#define _TC3(T1, T2, T3)        <T1, T2, T3>
#define _TC4(T1, T2, T3, T4)        <T1, T2, T3, T4>
#define _TC5(T1, T2, T3, T4, T5)        <T1, T2, T3, T4, T5>

/**
 * CLASS_END 类定义结束
 */
#define CLASS_END };

#define BASE_FINAL_CLASS_DEFINE \
protected:\
    _FORCE_INLINE_ static void onClassLoaded(gc::Class *clz) {}\
    friend class gc::ClassDB;\
public:\
    static const gc::Class *getClass();\
    const gc::Class *getInstanceClass() const;\
private:

#define BASE_FINAL_CLASS_DEFINE_T(TYPE) \
protected:\
    _FORCE_INLINE_ static void onClassLoaded(Class *clz) { \
        clz->setLabels(variant_map{{HObject::LABEL_CATEGORY, TYPE}}); \
    } \
    friend class ClassDB;\
public:\
    static const Class *getClass();\
    const HClass *getInstanceClass() const;\
private:

#define BASE_CLASS_DEFINE \
protected:\
    _FORCE_INLINE_ static void onClassLoaded(Class *clz) {}\
    friend class ClassDB;\
public:\
    static const Class *getClass();\
    virtual const Class *getInstanceClass() const;\
private:

#define BASE_CLASS_IMPLEMENT(CLZ) const Class *CLZ::getClass() {\
    if (!_class_contrainer<CLZ>::_class) {\
        const Class *clazz = ClassDB::getInstance()->find_loaded(ClassDB::connect("gc", #CLZ));\
        _class_contrainer<CLZ>::_class = clazz ? clazz : ClassDB::getInstance()->cl<CLZ>("gc", #CLZ, NULL);\
    }\
    return _class_contrainer<CLZ>::_class;\
}\
const Class *CLZ::getInstanceClass() const {\
    return CLZ::getClass();\
}

#define BASE_CLASS_IMPLEMENT_V(CLZ) const Class *CLZ::getClass() {\
    if (!_class_contrainer<CLZ>::_class) {\
        const Class *clazz = ClassDB::getInstance()->find_loaded(ClassDB::connect("gc", #CLZ));\
        _class_contrainer<CLZ>::_class = clazz ? clazz : ClassDB::getInstance()->vr<CLZ>("gc", #CLZ, NULL);\
    }\
    return _class_contrainer<CLZ>::_class;\
}\
const Class *CLZ::getInstanceClass() const {\
    return CLZ::getClass();\
}

#define NAME(name) static const StringName name(#name)

// --------------- for meta program ---------------


#define ENUM_BEGIN(NAME) typedef short NAME; \
enum {
#define ENUM_END };
#define E(L) ((short)L)
#define LABEL(KEY, VALUE)
#define LABELS(...)
#define METHOD
#define PROPERTY(NAME, GETTER, SETTER)
#define EVENT(RET_TYPE, NAME, ...) static gc::StringName EVENT_##NAME;
#define DEVENT(CLZ, NAME) gc::StringName CLZ::EVENT_##NAME(#NAME);

#define NOTIFICATION(NAME, ...) static gc::StringName NOTIFICATION_##NAME;
#define DNOTIFICATION(CLZ, NAME) gc::StringName CLZ::NOTIFICATION_##NAME(#NAME);

#ifdef USING_SCRIPT

#define SET_LABELS(...) cls->setLabels(variant_map{__VA_ARGS__});
#define ON_LOADED_BEGIN(CLZ, SUPER) _FORCE_INLINE_ static void onClassLoaded(gc::Class *CLZ) { \
    SUPER::onClassLoaded(CLZ);
#define ON_LOADED_END }

#define INITIALIZER(CLASS, TYPE, M) ADD_METHOD(CLASS, TYPE, M)
#define ADD_METHOD(CLASS, TYPE, M) CLASS->addMethod(gc::MethodImp_makeMethod<TYPE>(#M, &TYPE::M))
#define ADD_METHOD_D(CLASS, TYPE, M, ...) CLASS->addMethod(gc::MethodImp_makeMethod<TYPE>(#M, &TYPE::M, std::vector<gc::Variant>{__VA_ARGS__}))
#define ADD_METHOD_E(CLASS, TYPE, M_TYPE, M) CLASS->addMethod(MethodImp_makeMethod<TYPE>(#M, (M_TYPE)&TYPE::M))

#define ADD_PROPERTY(CLASS, ...) CLASS->addProperty(new gc::Property(CLASS, __VA_ARGS__))
#define ADD_PROPERTY_EX(CLASS, NAME, TYPE, GETTER, SETTER) ADD_PROPERTY(CLASS, #NAME, ADD_METHOD(CLASS, TYPE, GETTER), ADD_METHOD(CLASS, TYPE, SETTER))

#else

#define SET_LABELS(...)
#define INITIALIZER(CLASS, TYPE, M)
#define ON_LOADED_BEGIN(CLZ, SUPER)
#define ON_LOADED_END

#define ADD_METHOD(CLASS, TYPE, M)
#define ADD_METHOD_E(CLASS, TYPE, M_TYPE, M)
#define INITIALIZER(CLASS, TYPE, M)
#define ADD_PROPERTY(CLASS, ...)
#define ADD_PROPERTY_EX(CLASS, NAME, TYPE, GETTER, SETTER) 


#endif

// ----- getClass() and getInstanceClass()

#define DEFINE_GET_CLASS_NS(NS, NAME, SUPER, METHOD) \
static const __CLASS_NS(Class) *getClass() { \
    if (!__CLASS_NS(_class_contrainer)<NAME>::_class) {\
        const __CLASS_NS(Class) *cls = __CLASS_NS(ClassDB)::getInstance()->find_loaded(__CLASS_NS(ClassDB)::connect(NS, #NAME));\
        __CLASS_NS(_class_contrainer)<NAME>::_class = cls ? cls : __CLASS_NS(ClassDB)::getInstance()->METHOD<NAME>(NS, #NAME, SUPER::getClass()); \
    }\
    return __CLASS_NS(_class_contrainer)<NAME>::_class; \
} \
_FORCE_INLINE_ virtual const __CLASS_NS(Class) *getInstanceClass() const { \
    return NAME::getClass(); \
}\
static const __CLASS_NS(StringName) &getClassName() { \
    static const __CLASS_NS(StringName) name(NS "::" #NAME);\
    return name;\
}

#define DEFINE_GET_CLASS(NAME, SUPER, METHOD) \
static const __CLASS_NS(Class) *getClass() { \
    if (!__CLASS_NS(_class_contrainer)<NAME>::_class) {\
        const __CLASS_NS(Class) *cls = __CLASS_NS(ClassDB)::getInstance()->find_loaded(#NAME);\
        __CLASS_NS(_class_contrainer)<NAME>::_class = cls ? cls : __CLASS_NS(ClassDB)::getInstance()->METHOD<NAME>(NULL, #NAME, SUPER::getClass()); \
    }\
    return __CLASS_NS(_class_contrainer)<NAME>::_class;\
} \
_FORCE_INLINE_ virtual const __CLASS_NS(Class) *getInstanceClass() const { \
    return NAME::getClass(); \
}\
static const __CLASS_NS(StringName) &getClassName() { \
    static const __CLASS_NS(StringName) name(#NAME);\
    return name;\
}

#define SUPPORT_VARIANT(TYPE) _FORCE_INLINE_ operator gc::Variant() const { \
    return gc::Variant::memoryVar(this); \
} \
_FORCE_INLINE_ TYPE(const gc::Variant &var) : TYPE() { \
    if (var.getTypeClass()->isTypeOf(TYPE::getClass())) var.getMemory(*this); \
}


#define PARAMS(...) __VA_ARGS__

#define INITIALIZE(CLASS, PARAMS, PROGRAMS) \
_FORCE_INLINE_ CLASS(PARAMS):CLASS(){PROGRAMS}

#define NAMESPACE(nc) namespace nc

// ------ LOG


#ifndef DEBUG
#   define LOG(TAG, ...)
#else

#   define LOG(TAG, ...) LOG##TAG(__VA_ARGS__)


#   if defined(__ANDROID__)

#include <android/log.h>

#       define LOGe(...) \
    __android_log_print(ANDROID_LOG_ERROR, "G-Lib", __VA_ARGS__)
#       define LOGi(...) \
    __android_log_print(ANDROID_LOG_INFO, "G-Lib", __VA_ARGS__)
#       define LOGw(...) \
    __android_log_print(ANDROID_LOG_WARN, "G-Lib", __VA_ARGS__)

#   else

#       define LOGe(...) \
    printf("Error: ");\
    printf(__VA_ARGS__); \
    printf("\r\n")
#       define LOGi(...) \
    printf("Info: ");\
    printf(__VA_ARGS__); \
    printf("\r\n")
#       define LOGw(...) \
    printf("Warning: ");\
    printf(__VA_ARGS__); \
    printf("\r\n")

#   endif

#endif

// ----------- Types

#define pointer_map     std::map<void*, void*>
#define variant_map     std::map<void*, gc::Variant>
#define ref_map         std::map<void*, gc::Reference>
#define pointer_vector  std::vector<void*>
#define variant_vector  std::vector<gc::Variant>
#define float_vector    std::vector<float>
#define ref_vector      std::vector<gc::Reference>
#define b8_vector       std::vector<u_int8_t>
#define pointer_list    std::list<void*>
#define pointer_set     std::set<void*>
#define ref_list        std::list<gc::Reference>
#define variant_list    std::list<gc::Variant>

#define b8_mask     0xff
#define b16_mask    0xffff
#define b32_mask    0xffffffff

#endif //gc_DEFINE_H
