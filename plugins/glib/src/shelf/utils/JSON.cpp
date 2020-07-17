//
// Created by gen on 2020/5/27.
//

#include "JSON.h"
#include <core/Map.h>
#include <core/String.h>

using namespace nlohmann;
using namespace gc;
using namespace gs;
using namespace std;

gc::Variant JSON::parse(const nlohmann::json &obj) {
    switch (obj.type()) {
        case detail::value_t::object: {
            Map map;
            for (auto it = obj.begin(), _e = obj.end(); it != _e; ++it) {
                map->set(it.key(), parse(it.value()));
            }
            return map;
        }
        case detail::value_t::array: {
            Array arr;
            for (auto it = obj.begin(), _e = obj.end(); it != _e; ++it) {
                arr.push_back(parse(it.value()));
            }
            return arr;
        }
        case detail::value_t::boolean: {
            return (bool)obj;
        }
        case detail::value_t::string: {
            return (string)obj;
        }
        case detail::value_t::number_integer: {
            return (long)obj;
        }
        case detail::value_t::number_unsigned: {
            return (unsigned long)obj;
        }
        case detail::value_t::number_float: {
            return (float)obj;
        }
        default:
            return Variant::null();
    }
}

nlohmann::json JSON::serialize(const gc::Variant &variant) {
    switch (variant.getType()) {
        case Variant::TypeBool:
            return (bool)variant;
        case Variant::TypeChar:
        case Variant::TypeShort:
        case Variant::TypeInt:
            return (int)variant;
        case Variant::TypeLong:
        case Variant::TypeLongLong:
            return (long long)variant;
        case Variant::TypeFloat:
            return (float)variant;
        case Variant::TypeDouble:
            return (double)variant;
        case Variant::TypeStringName:
            return variant.str();
        case Variant::TypeReference: {
            const Class *cls = variant.getTypeClass();
            if (cls->isTypeOf(gc::_Map::getClass())) {
                nlohmann::json obj = nlohmann::json::object();
                gc::Map map = variant;
                for (auto it = map->begin(), _e = map->end(); it != _e; ++it) {
                    obj[it->first] = serialize(it->second);
                }
                return obj;
            } else if (cls->isTypeOf(gc::_Array::getClass())) {
                nlohmann::json jarr = nlohmann::json::array();
                gc::Array arr = variant;
                for (auto it = arr->begin(), _e = arr->end(); it != _e; ++it) {
                    jarr.push_back(serialize(*it));
                }
                return jarr;
            } else if (cls->isTypeOf(gc::_String::getClass())) {
                return variant.str();
            } else {
                return nullptr;
            }
        }
        default: return nullptr;
    }
}