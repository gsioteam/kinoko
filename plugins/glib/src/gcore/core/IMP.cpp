//
// Created by gen on 16/6/21.
//

#include "Class.h"
#include "StringName.h"
#include "Ref.h"
#include "script/ScriptClass.h"
#include "script/ScriptInstance.h"
#include "script/Script.h"
#include "Variant.h"
#include "FixType.h"
#include "String.h"
#include "Reference.h"
#include "Method.h"
#include "MethodImp.h"
#include "Property.h"
#include "Base.h"
#include "Callback.h"
#include "script/Script.h"
#include "Array.h"
#include "Hash.h"
#include "Data.h"
#include "Map.h"
#include <sys/time.h>
#include <cstring>
#include <stdarg.h>
#include <string.h>

using namespace std;
using namespace gc;

b8_vector Data::readAll() {
    size_t size = getSize();
    b8_vector res(size);
    if (size) {
        res.resize(size);
        seek(0, SEEK_SET);
        read(res.data(), 1, size);
    }
    return res;
}

string Data::text() {
    string res;
    auto buf = readAll();
    res.reserve(buf.size() + 1);
    for (int i = 0, t = buf.size(); i < t; ++i) {
        uint8_t ch = buf[i];
        if (ch) {
            res.push_back(ch);
        }
    }
    return res;
}


Ref<Data> Data::fromString(const std::string &str) {
    size_t len = str.size();
    char *chs = (char *)malloc(len);
    memcpy(chs, str.data(), len);
    return new_t(BufferData, chs, len, BufferData::Retain);
}

void BufferData::seek(size_t seek, int type) {
    switch (type) {
        case SEEK_SET: {
            offset = seek;
            break;
        }
        case SEEK_CUR: {
            offset += seek;
            break;
        }
        case SEEK_END: {
            offset = size - seek - 1;
            break;
        }
    }
}

size_t BufferData::read(void *chs, size_t size, size_t nitems) {
    size_t total = getSize();
    if (offset < total) {
        const uint8_t *buffer = (const uint8_t *)getBuffer();
        uint8_t *dist = (uint8_t*)chs;
        size_t readed = 0;
        while (offset + size <= total) {
            size_t read = min(total - offset, size);
            memcpy(dist + offset, buffer + offset, size);
            ++readed;
            offset += size;
        }
        return readed;
    }else {
        LOG(e, "Range out of bound.");
        return -1;
    }
}

void BufferData::initialize(void* buffer, long size, RetainType retain) {
    this->size = size;
    switch (retain) {
        case Retain: {
            this->b_buffer = buffer;
            this->retain = true;
        }
            break;
        case Copy: {
            this->b_buffer = malloc(size);
            ::memcpy(this->b_buffer, buffer, size);
            this->retain = true;
            break;
        }
        case Ref: {
            this->b_buffer = buffer;
            this->retain = false;
            break;
        }

        default:
            break;
    }
}

size_t FileData::getSize() const {
    FileData *that = const_cast<FileData*>(this);
    if (file) {
        size_t s = ftell(file);
        fseek(that->file,0,SEEK_END);
        size_t size = ftell(file);
        fseek(file, s, SEEK_SET);
        return size;
    }
    return 0;
}

size_t FileData::read(void *chs, size_t size, size_t nitems) {
    if (file) {
        return fread(chs, size, nitems, file);
    }
    return -1;
}

b8_vector FileData::readAll() {
    if (file) {
#define BUF_SIZE (8 * 1024)
        b8_vector res;
        fseek(file,0, SEEK_SET);
        size_t readed = 0;
        uint8_t buf[BUF_SIZE];
        while ((readed = fread(buf, 1, BUF_SIZE, file)) > 0) {
            size_t size = res.size();
            res.resize(size + readed);
            memcpy(res.data() + size, buf, readed);
        }
        fseek(file,0, SEEK_END);
        return res;
    }
    return b8_vector();
}

size_t MultiData::read(void *chs, size_t size, size_t nitems) {
    size_t total = getSize();
    if (offset < total) {
        const uint8_t *buffer = this->buffer.data();
        uint8_t *dist = (uint8_t*)chs;
        size_t readed = 0;
        while (offset + size <= total) {
            size_t read = min(total - offset, size);
            memcpy(dist + offset, buffer + offset, size);
            ++readed;
            offset += size;
        }
        return readed;
    }else {
        LOG(e, "Range out of bound.");
        return -1;
    }
}

size_t MultiData::write(uint8_t *buf, size_t size, size_t nitems) {
    size_t writed = 0, offset = buffer.size();
    for (int i = 0; i < nitems; ++i) {
        buffer.resize(offset + size);
        memcpy(buffer.data() + offset, buf + writed, size);
        writed += size;
        offset += size;
    }
    return writed;
}

struct Object::Scripts  {
    list<ScriptInstance*> scripts;
    Scripts() {}
    ~Scripts() {
        for (auto it = scripts.begin(), _e = scripts.end(); it != _e; ++it) {
            (*it)->setTarget(NULL);
        }
    }
};

ClassDB* ClassDB::instance = NULL;
std::mutex ClassDB::mtx;

Reference Reference::nullRef;

const Variant Variant::_null;

void Object::addScript(ScriptInstance *ins) {
    if (!scripts_container) {
        scripts_container = new Scripts;
    }
    scripts_container->scripts.push_back(ins);
}

void Object::removeScript(ScriptInstance *instance) {
    if (scripts_container) {
        auto it = scripts_container->scripts.begin();
        while (it != scripts_container->scripts.end()) {
            if (*it == instance) {
                it = scripts_container->scripts.erase(it);
            }else ++it;
        }
    }
}

void Object::clearScripts() {
    if (scripts_container) {
        delete scripts_container;
        scripts_container = nullptr;
    }
}

ScriptInstance* Object::findScript(const gc::StringName &name) {
    if (scripts_container) {
        for (auto it = scripts_container->scripts.begin(), _e = scripts_container->scripts.end(); it != _e; ++it) {
            if ((*it)->getScript()->getName() == name) {
                return *it;
            }
        }
    }
    return NULL;
}
ScriptInstance *Object::findScript(const Script *script) {
    if (scripts_container) {
        for (auto it = scripts_container->scripts.begin(), _e = scripts_container->scripts.end(); it != _e; ++it) {
            if ((*it)->getScript() == script) {
                return *it;
            }
        }
    }
    return NULL;
}

#ifdef USING_SCRIPT
void Object::apply(const StringName &name, Variant *result, const Variant **params, int count) {
    if (scripts_container) {
        list<ScriptInstance*> scripts = scripts_container->scripts;
        for (auto it = scripts.begin(), _e = scripts.end(); it != _e; ++it) {
            if (result && !*result)
                *result = (*it)->apply(name, params, count);
            else (*it)->apply(name, params, count);
        }
        return;
    }
    if (result)
        *result = Variant::null();
}
#endif

void Base::call(const StringName &name, Variant *result, const Variant **params, int count) {
    const Method *method = getInstanceClass()->getMethod(name);
    if (method) {
        if (result) {
            *result = method->call(this, params, count);
        }
        else {
            method->call(this, params, count);
        }
    }else {
        missMethod(name, result, params, count);
    }
}

bool Base::copy(const Object *other) {
    if (other->getInstanceClass()->isTypeOf(getInstanceClass())) {
        _copy(other);
        return true;
    }
    return false;
}

Variant Base::var()  {
    return Variant(this);
}

//template <typename T>
//T trans_target(void *target, const Class *type) {
//    if (type && type->isTypeOf(HObject::getClass())) {
//        Number *num = ((HObject*)target)->cast_to<Number>();
//        if (num)
//            return num->operator T();
//    }
//    return (T)(long)target;
//}


struct VariantHelper {

};
template <typename T>
T trans_target2(Variant::u_value value, Variant::Type type) {
    switch (type) {
        case Variant::TypeNull: {
            return (T)0;
        }
        case Variant::TypeChar: {
            return (T)value.v_char;
        }
        case Variant::TypeShort: {
            return (T)value.v_short;
        }
        case Variant::TypeInt: {
            return (T)value.v_int;
        }
        case Variant::TypeLong: {
            return (T)value.v_long;
        }
        case Variant::TypeLongLong: {
            return (T)value.v_longlong;
        }
        case Variant::TypeFloat: {
            return (T)value.v_float;
        }
        case Variant::TypeDouble: {
            return (T)value.v_double;
        }
        default: {
            return (T)(long)value.v_pointer;
        }
    }
}

bool Variant::operator==(const Variant &other) const {
    const Class *type = getTypeClass();
    if (type == other.getTypeClass()) {
        if (type == Char::getClass()) {
            return operator char () == (char)other;
        }else if (type == Short::getClass()) {
            return operator short () == (short)other;
        }else if (type == Integer::getClass()) {
            return operator int() == (int)other;
        }else if (type == Long::getClass()) {
            return operator long() == (long)other;
        }else if (type == Float::getClass()) {
            return operator float() == (float)other;
        }else if (type == Double::getClass()) {
            return operator float() == (float)other;
        }else if (type == _String::getClass()) {
            return strcmp(operator const char *(), (const char *)other) == 0;
        }else if (type == StringName::getClass()) {
            StringName sn = operator StringName();
            return sn == (&other)->operator StringName();
        }else {
            return get() == other.get();
        }
    }else {
        return false;
    }
}

Variant::operator char() const {
    return trans_target2<char>(value, type);
}
Variant::operator signed char() const {
    return trans_target2<signed char>(value, type);
}
Variant::operator unsigned char() const {
    return trans_target2<unsigned char>(value, type);
}
Variant::operator short() const {
    return trans_target2<short>(value, type);
}
Variant::operator unsigned short() const {
    return trans_target2<unsigned short>(value, type);
}
Variant::operator int() const {
    return trans_target2<int>(value, type);
}
Variant::operator unsigned int() const {
    return trans_target2<unsigned int>(value, type);
}
Variant::operator long() const {
    return trans_target2<long>(value, type);
}
Variant::operator unsigned long() const {
    return trans_target2<unsigned long>(value, type);
}
Variant::operator long long() const {
    return trans_target2<long long>(value, type);
}
Variant::operator unsigned long long() const {
    return trans_target2<long long>(value, type);
}
Variant::operator float() const {
    return trans_target2<float>(value, type);
}
Variant::operator double() const {
    return trans_target2<double>(value, type);
}

Variant::operator void *() const {
    if (type >= TypePointer) {
        return value.v_pointer;
    }
    return NULL;
}

Variant::operator StringName() const {
    const Class *type = getTypeClass();
    if (type->isTypeOf(StringName::getClass())) {
        return StringName(this->operator void*());
    }else if (type->isTypeOf(_String::getClass())){
        StringName ret(str().c_str());
        return ret;
    }
    return StringName::null();
}

const Class* Variant::getTypeClass() const {
    switch (type) {
        case TypeObject:
        case TypeReference: {
            return get<Object>()->getInstanceClass();
        }
        case TypeNull: {
            return Null::getClass();
        }
        default: {
            return class_type;
        }
    }
}
Variant::Type Variant::getType() const {
    return type;
}

void Variant::release() {
    switch (type) {
        case TypeReference: {
            Object *ptr = get<Object>();
            if (ptr->release() == 0) {
                delete ptr;
            }
            break;
        }
        case TypeMemory: {
            free(value.v_pointer);
            break;
        }
    }
    value.v_pointer = NULL;
    type = TypeNull;
    class_type = NULL;
}

void Variant::retain(const u_value &value, const Class *class_type, int8_t type) {
    if (type < 0) {
        if (class_type == NULL) {
            type = value.v_pointer ? TypePointer : TypeNull;
        }else if (class_type == Char::getClass()) {
            type = TypeChar;
        }else if (class_type == Short::getClass()) {
            type = TypeShort;
        }else if (class_type == Integer::getClass()) {
            type = TypeInt;
        }else if (class_type == Long::getClass()) {
            type = TypeLong;
        }else if (class_type == LongLong::getClass()) {
            type = TypeLongLong;
        }else if (class_type == Float::getClass()) {
            type = TypeFloat;
        }else if (class_type == Double::getClass()) {
            type = TypeDouble;
        }else if (class_type == StringName::getClass()) {
            type = TypeStringName;
        }else if (class_type->isTypeOf(Object::getClass())) {
            type = TypeReference;
        }else if (class_type->isTypeOf(Base::getClass())) {
            type = TypeObject;
        }else {
            type = TypePointer;
        }
    }
    switch (type) {
        case TypeReference: {
            static_cast<Object *>(value.v_pointer)->retain();
            this->value = value;
            break;
        }
        case TypeMemory: {
            this->value.v_pointer = malloc(class_type->getSize());
            ::memcpy(this->value.v_pointer, value.v_pointer, class_type->getSize());
            break;
        }
        default: {
            this->value = value;
        }
    }
    this->type = type;
    this->class_type = class_type;
}

Variant::Variant(char n) : Variant() {
    value.v_char = n;
    type = TypeChar;
    class_type = Char::getClass();
}
Variant::Variant(short n) : Variant() {
    value.v_short = n;
    type = TypeShort;
    class_type = Short::getClass();
}
Variant::Variant(int n) : Variant() {
    value.v_int = n;
    type = TypeInt;
    class_type = Integer::getClass();
}
Variant::Variant(long n) : Variant() {
    value.v_long = n;
    type = TypeLong;
    class_type = Long::getClass();
}
Variant::Variant(long long n) : Variant() {
    value.v_longlong = n;
    type = TypeLongLong;
    class_type = LongLong::getClass();
}


Variant::Variant(unsigned char n) : Variant() {
    value.v_char = n;
    type = TypeChar;
    class_type = Char::getClass();
}
Variant::Variant(unsigned short n) : Variant() {
    value.v_short = n;
    type = TypeShort;
    class_type = Short::getClass();
}
Variant::Variant(unsigned int n) : Variant() {
    value.v_int = n;
    type = TypeInt;
    class_type = Integer::getClass();
}
Variant::Variant(unsigned long n) : Variant() {
    value.v_long = n;
    type = TypeLong;
    class_type = Long::getClass();
}
Variant::Variant(unsigned long long n) : Variant() {
    value.v_longlong = n;
    type = TypeLongLong;
    class_type = LongLong::getClass();
}

Variant::Variant(float n) : Variant() {
    value.v_float = n;
    type = TypeFloat;
    class_type = Float::getClass();
}
Variant::Variant(double n) : Variant() {
    value.v_double = n;
    type = TypeDouble;
    class_type = Double::getClass();
}
Variant::Variant(bool n) : Variant()  {
    value.v_bool = n;
    type = TypeBool;
    class_type = Boolean::getClass();
}

Variant::Variant(const Base *obj) : Variant() {
    if (obj) {
        class_type = obj->getInstanceClass();
        retain(u_value{v_pointer: (void*)obj}, class_type);
    }
}

Variant::Variant(void *ptr) : Variant() {
    if (ptr) {
        retain(u_value{v_pointer: ptr}, NULL);
    }
}

Variant::Variant(const StringName &name) : Variant() {
    retain(u_value{.v_pointer = (void *)name}, StringName::getClass(), TypeStringName);
}

Variant::operator bool() const {
    if (type != TypeNull) {
        return trans_target2<bool>(value, type);
    }
    return false;
}

Variant::operator string() const {
    if (type) {
        return str();
    }else {
        return "";
    }
}

Variant::Variant(const string &str) : Variant() {
    const Class *cls = _String::getClass();
    String s(str);
    retain(u_value{.v_pointer= s.get()}, cls);
}

string Variant::str() const {
    switch (type) {
        case TypeReference: {
            if (class_type == _String::getClass()) {
                return get<_String>()->str();
            } else {
                return get()->str();
            }
            break;
        }
        case TypeObject: {
            return get()->str();
        }
        case TypeStringName: {
            return StringName(get<void>()).str();
        }
        case TypeBool: {
            return bool(*this) ? "true":"false";
        }
        case TypeChar: {
            char ch[2];
            ch[0] = *this;
            ch[1] = 0;
            return ch;
        }
        case TypeShort:
        case TypeInt: {
            int n = *this;
            char str[256];
            sprintf(str, "%d", n);
            return str;
        }
        case TypeLong: {
            long n = *this;
            char str[256];
            sprintf(str, "%ld", n);
            return str;
        }
        case TypeLongLong: {
            long long n = *this;
            char str[256];
            sprintf(str, "%lld", n);
            return str;
        }
        case TypeFloat:
        case TypeDouble: {
            double n = *this;
            char str[256];
            sprintf(str, "%f", n);
            return str;
        }
    }
    return "";
}

bool Variant::isRef(int8_t type) {
    return type == TypeReference;
}

Variant::operator const char *() const {
    if (type == TypeReference && class_type == _String::getClass()) {
        return get<_String>()->c_str();
    }else if (type == TypeStringName) {
        return StringName(get<void>()).str();
    }
    return "";
}

Variant::operator Base *() const {
    return get<Base>();
}

Variant::Variant(const char *str) : Variant() {
    const Class *cls = _String::getClass();
    String s(str);
    retain(u_value{v_pointer: s.get()}, cls);
}

Variant ptr(void *pointer) {
    return Variant(pointer);
}

void Reference::release() {
    if (ptr) {
        if (ptr->release() == 0) {
            delete ptr;
            ptr = NULL;
            return;
        }
    }
}

string Reference::str() const {
    if (ptr) {
        return get()->str();
    }else return "";
}

void Reference::retain() {
    IV(ptr, retain());
}


Reference::Reference(const Variant &other) {
    if (other.isRef()) {
        const Reference &r = other.ref();
        ptr = r.ptr;
        retain();
    }else {
        ptr = NULL;
    }
}

Reference& Reference::operator=(Object *p) {
    release();
    ptr = p;
    IV(ptr, retain());
    return *this;
}

void Weak::untouch() {
    if (ptr) {
        ptr->off(Object::EVENT_DESTROY, on_delete);
    }
}

void Weak::touch() {
    if (ptr) {

        function<void()> func = bind(&Weak::onDelete, this);
        on_delete = C(func);
        ptr->on(Object::EVENT_DESTROY, on_delete);
    }
}

void Weak::onDelete() {
    std::lock_guard<std::mutex> lock(mtx);
    ptr = NULL;
}

//void Variant::operator=(const HObject *object) {
//    if (object) {
//        const HClass *cls = object->getInstanceClass();
//        if (isRef(cls)) ref((const Reference *) object, cls);
//        else {
//            setMem((void *) object, cls);
//            ((HObject *)mem)->scripts_container->scripts_ref_count++;
//        }
//    }else {
//        if (isRef()) reference = NULL;
//        else if (mem) {
//            free(mem);
//            mem = NULL;
//        }
//        type = NULL;
//    }
//}

namespace gc {
    const StringName MethodInitialer("initialize");
}

const Method *Class::addMethod(const Method *method) {
    if (method->getName() == MethodInitialer) {
        setInitializer(method);
    }else
        methods[method->getName()] = (void*)method;
    return method;
}

const Property *Class::addProperty(const Property *property) {
    properties[property->getName()] = (void*)property;
    return property;
}

Property::Property(const Class *clazz, const char *name, const Method *getter,
                   const Method *setter) {
    if ((getter && getter->getType() == Method::Static) || (setter && setter->getType() == Method::Static)) {
        LOG(e, "Setter and Getter must be a member method.");
    }else {
        this->getter = getter;
        this->setter = setter;
    }
    this->clazz = clazz;
    this->name = new StringName(name);
}

Property::Property(const Class *clazz, const char *name, const Method *getter,
                   const Method *setter, const variant_map &labels) : Property(clazz, name, getter, setter) {
    this->labels = new variant_map;
    this->labels->operator=(labels);
}

Property::~Property() {
    if (labels) delete labels;
    delete name;
}

BASE_CLASS_IMPLEMENT(Reference)
BASE_CLASS_IMPLEMENT_V(Method)
BASE_CLASS_IMPLEMENT_V(Null)

Variant Method::call(void *obj, const Variant **params, int count) const {
    int pc = getParamsCount();
    int dc = getDefaultCount();
    if (count < pc) {
        if (count + dc < pc) {
            LOG(e, "(%s) The variant count mush be greater than %d.", getName().str(), pc - dc);
            return Variant();
        }else {
            const Variant **vs = (const Variant **)malloc(sizeof(const Variant *) * pc);
            int i = 0;
            for (; i < count; ++i) {
                vs[i] = params[i];
            }
            for (; i < pc; i++) {
                vs[i] = &default_values[dc - (i - count) - 1];
            }
            Variant ret = _call(obj, vs);
            free(vs);
            return ret;
        }
    }else {
        return _call(obj, params);
    }
}

Method::Method(const char *name) : return_type(NULL), params_types(NULL), labels(NULL), default_values(NULL) {
    *(uint32_t*)(&params) = 0;
    this->name = name;
}

Method::~Method() {
    if (params_types) free(params_types);
    if (labels) free(labels);
    if (default_values) delete []default_values;
    delete name;
}

BASE_CLASS_IMPLEMENT(Variant)


BASE_CLASS_IMPLEMENT(Property)

const pointer_map &Class::getMethods() const {
    return methods;
}

const pointer_map &Class::getProperties() const {
    return properties;
}

void Class::setLabels(const variant_map &labels) {
    this->labels = labels;
}

const Class *ClassDB::find(const StringName &fullname) {
    const Class *result = find_loaded(fullname);
    if (!result) {
        auto it = class_loaders.find(fullname);
        result = it == class_loaders.end() ? NULL : (*(ClassLoader*)it->second)();
    }
    return result;
}

Variant Class::call(const StringName &name, object_type obj, const Variant **params, int count) const {
    const Method *mtd = getMethod(name);
    if (mtd) return mtd->call(obj, params, count);
    return Variant::null();
}

const Class *ClassDB::find_loaded(const StringName &fullname) {
    auto it = classes_index.find(fullname);
    return (const Class *) (it == classes_index.end() ? NULL : it->second);
}

const Class *Reference::getType() const {
    return ptr? ptr->getInstanceClass() : NULL;
}

Class::~Class() {
    delete fullname;
}

Class::Class(const char *ns, const char *name) : Class() {
    this->ns = ns;
    this->name = name;
    fullname = new StringName(ns ? (string(ns) + "::" + name).c_str() : name);
}

void Reference::call(const StringName &name, Variant *result, const Variant **params, int count) {
    if (ptr) {
        ptr->call(name, result, params, count);
    }
}

void Reference::ref(const Reference *other) {
    if (ptr != other->ptr)  {
        release();
        ptr = other->ptr;
        retain();
    }else {
        ptr = other->ptr;
    };
}

Variant _Callback::invoke(const Array &params) {
    pointer_vector vec;
    Variant var = params;
    vec.push_back((void*)&var);
    Variant ret;
    apply("_invoke", &ret, (const Variant **)vec.data(), vec.size());
    return ret;
}


ScriptInstance *Script::getScriptInstance(const Object *target) const {
    if (target->scripts_container) {
        for (auto it = target->scripts_container->scripts.begin(),
             _e = target->scripts_container->scripts.end(); it != _e; ++it) {
            if ((*it)->getScript() == this) {
                return *it;
            }
        }
    }
    return NULL;
}

string _Array::str() const {
    stringstream ss;
    ss << "[";
    for (auto it = variants.begin(), _e = variants.end(); it != _e; ++it) {
        ss << (*it).str();
    }
    ss << "]";
    return ss.str();
}

bool _Array::triger(ArrayEvent event, long idx, const Variant &v) {
    Callback *lis = (Callback*)listener;
    if (lis)
        return (*lis)->invoke(Array{event, idx, v});
    return false;
}

bool _Array::replace(long idx, const Variant &v1, const Variant &v2) {
    Callback *lis = (Callback*)listener;
    if (lis)
        return (*lis)->invoke(Array{E(Replace), idx, v1, v2});
    else return false;
}

void _Array::push_back(const Variant &var) {
    variants.push_back(var);
    if (listener) triger(E(Insert), variants.size()-1, var);
}


void _Array::insert(long n, const Variant &var) {
    if (n <= variants.size()) {
        auto it = variants.begin() + n;
        if (listener) triger(E(Insert), n, *it);
        variants.insert(it, var);
    }
}

void _Array::erase(long n) {
    if (n < variants.size()) {
        auto it = variants.begin() + n;
        if (listener) triger(E(Remove), n, *it);
        variants.erase(it);
    }
}

void _Array::set(long idx, const Variant &var) {
    if (idx < variants.size()) {
        Variant old = variants[idx];
        variants[idx] = var;
        replace(idx, var, old);
    }
}

void _Array::remove(const Variant &var) {
    long count = 0;
    for (auto it = variants.begin(), _e = variants.end(); it != _e; ++it) {
        if (var == *it) {
            if (listener) triger(E(Remove), count, var);
            it = variants.erase(it);
        }else {
            ++it;
        }
        ++count;
    }
}

long _Array::find(const Variant &var) {
    long i = variants.size() - 1;
    for (; i >= 0; --i) {
        if (variants[i] == var) {
            break;
        }
    }
    return i;
}

Variant _Array::pop_back() {
    if (variants.size()) {
        Variant ret = variants.back();
        if (listener) triger(E(Remove), variants.size() - 1, ret);
        variants.pop_back();
        return ret;
    }else {
        return Variant::null();
    }
}

void _Array::setListener(const Callback &callback) {
    Callback *lis;
    if (!listener) {
        lis = new Callback;
        listener = lis;
    }else {
        lis = (Callback*)listener;
    }
    lis->operator=(callback);
}

_Array::~_Array() {
    if (listener) {
        delete (Callback*)listener;
    }
}

static const unsigned int seed = 131;
static pointer_map *stringDB;

_FORCE_INLINE_ uint32_t bkdrHash(const char *str) {
    unsigned int hash = 0;
    while (*str) hash = hash * seed + (*str++);
    return (hash & 0x7FFFFFFF);
}

const char *make_cs(const char *cs) {
    if (cs) {
        int size = strlen(cs) + 1;
        char *chs = (char*)malloc(size * sizeof(char));
        strcpy(chs, cs);
        chs[size - 1] = 0;
        return chs;
    }
    return NULL;
}

int getName(const char *str, uint32_t h, const char **res = NULL) {
    if (!stringDB) stringDB = new pointer_map;
    auto f = stringDB->find((void*)h);
    if (f == stringDB->end()) {
        pointer_vector *v = new pointer_vector;
        const char *cname = make_cs(str);
        v->push_back((void*)cname);
        stringDB->operator[]((void*)h) = v;
        if (res) *res = cname;
        return 0;
    } else {
        pointer_vector *v = (pointer_vector *) f->second;
        int count = 0;
        for (auto it = v->begin(), _e = v->end(); it != _e; ++it) {
            const char *cname = (const char *)*it;
            if (strcmp(cname, str) == 0) {
                if (res) *res = cname;
                return count;
            }
            ++count;
        }
        const char *cname = make_cs(str);
        v->push_back((void*)cname);
        if (res) *res = cname;
        return count;
    }
}

//void *hicore::h(const char *chs) {
//    uint32_t h = bkdrHash(chs);
//    return make_key(h, getIndex(chs, h));
//}
//
//void *hicore::h(const string &str) {
//    const char *chs = str.c_str();
//    uint32_t h = bkdrHash(chs);
//    return make_key(h, getIndex(chs, h));
//}

void *gc::h(const char *chs) {
    uint32_t h = bkdrHash(chs);
    const char *ret;
    getName(chs, h, &ret);
    return (void*)ret;
}

//const char *hicore::s(uint64_t key) {
//    if (stringDB && key > b32_mask) {
//        uint32_t h = key >> 32 & b32_mask;
//        auto f = stringDB->find(h);
//        if (f != stringDB->end()) {
//            pointer_vector *v = (pointer_vector *) f->second;
//            uint32_t i;
//            if (v && (i = key & b32_mask) < v->size()) {
//                return (const char*)v->operator[](i);
//            }
//        }
//    }
//    return NULL;
//}


void ClassDB::loadClasses() {
    Object::getClass();
    Callback::getClass();
    _Array::getClass();
    _Map::getClass();
    ClassDB::reg<Data>();
    ClassDB::reg<BufferData>();
}


void EventManager::EventHandler::operator<<(const gc::Callback &cb) {
    auto it = manager.events.find(name);
    if (it == manager.events.end()) {
        manager.events[name] = CallbackStack();
    }
    CallbackStack &callStack = manager.events[name];
    callStack.push_back(cb);
}

void EventManager::EventHandler::operator>>(const gc::Callback &cb) {
    auto it = manager.events.find(name);
    if (it != manager.events.end()) {
        it->second.remove(cb);
    }
}

void EventManager::EventHandler::call(const variant_vector &variants) const {
    auto it = manager.events.find(name);
    if (it != manager.events.end()) {
        CallbackStack &callbacks = it->second;
        for (auto it1 = callbacks.begin(); it1 != callbacks.end(); ++it1) {
            if (*it1) {
                it1->get()->cast_to<_Callback>()->invoke(variants);
            }
        }
    }
}

void Object::on(const StringName &name, const Callback &callback) {
    if (!event_manager) {
        event_manager = new EventManager();
    }
    event_manager->operator[](name) << callback;
}


void Object::off(const StringName &name, const Callback &callback) {
    if (event_manager) {
        event_manager->operator[](name) >> callback;
    }
}

void Object::_trigger(const StringName &name, const variant_vector &params) {
    if (event_manager) {
        event_manager->operator[](name).call(params);
    }
}

Object::~Object() {
    trigger(EVENT_DESTROY);
    if (event_manager) delete event_manager;
    if (scripts_container) delete scripts_container;
}

const StringName Object::EVENT_DESTROY("DESTROY");
const StringName Base::KEY_INITIALIZE("initialize");


StringName StringName::_null;

BASE_CLASS_IMPLEMENT(StringName)

BASE_CLASS_IMPLEMENT(Char)
BASE_CLASS_IMPLEMENT(Short)
BASE_CLASS_IMPLEMENT(Integer)
BASE_CLASS_IMPLEMENT(Long)
BASE_CLASS_IMPLEMENT(LongLong)
BASE_CLASS_IMPLEMENT(Float)
BASE_CLASS_IMPLEMENT(Double)
BASE_CLASS_IMPLEMENT(Boolean)
