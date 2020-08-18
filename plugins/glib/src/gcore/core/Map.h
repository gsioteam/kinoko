//
// Created by mac on 2017/6/10.
//

#ifndef GSAV2_0_MAP_H
#define GSAV2_0_MAP_H

#include <map>
#include "Ref.h"
#include "Array.h"
#include "core_define.h"

namespace gc {
    CLASS_BEGIN_N(_Map, Object)

        std::map<std::string, Variant> _map;

    public:
        _FORCE_INLINE_ _Map() {}
        _FORCE_INLINE_ _Map(const std::map<std::string, Variant> &m) : _map(m) {}
        _FORCE_INLINE_ _Map(std::map<std::string, Variant> &&m) : _map(m) {}
        _FORCE_INLINE_ _Map(std::initializer_list<std::map<const std::string, Variant>::value_type> list) : _map(list) {
        }
    
        METHOD const Variant &get(const std::string &key) const {
            auto it = _map.find(key);
            if (it == _map.end()) {
                return Variant::null();
            }
            return it->second;
        }

        METHOD _FORCE_INLINE_ void set(const std::string &key, const Variant &val) {
            _map[key] = val;
        }

        _FORCE_INLINE_ std::map<std::string, Variant>::iterator begin() {
            return _map.begin();
        }

        _FORCE_INLINE_ std::map<std::string, Variant>::iterator end() {
            return _map.end();
        }
        _FORCE_INLINE_ std::map<std::string, Variant>::iterator find(const std::string &key) {
            return _map.find(key);
        };

        METHOD _FORCE_INLINE_ void erase(const std::string &key) {
            _map.erase(key);
        }

        _FORCE_INLINE_ Variant &at(const std::string &key) {
            return  _map[key];
        }
        METHOD _FORCE_INLINE_ long size() const {
            return _map.size();
        }
        METHOD Array keys() const {
            Array ks;
            for (auto it = _map.begin(), _e = _map.end(); it != _e; ++it) {
                ks.push_back(it->first);
            }
            return ks;
        }
        METHOD _FORCE_INLINE_ void clear() {
            _map.clear();
        }

    protected:
        ON_LOADED_BEGIN(cls, Object)
            ADD_METHOD(cls, _Map, get);
            ADD_METHOD(cls, _Map, set);
            ADD_METHOD(cls, _Map, erase);
            ADD_METHOD(cls, _Map, size);
            ADD_METHOD(cls, _Map, keys);
            ADD_METHOD(cls, _Map, clear);
        ON_LOADED_END
    CLASS_END

    CLASS_BEGIN_TN(Map, Ref, 1, _Map)

    public:
        _FORCE_INLINE_ Map() : Ref(new _Map()) {}
        _FORCE_INLINE_ Map(const std::map<std::string, Variant> &_map) : Ref(new _Map(_map)) {
        }
        _FORCE_INLINE_ Map(std::initializer_list<std::map<const std::string, Variant>::value_type> list) : Ref(new _Map(list)) {
        }
        _FORCE_INLINE_ Map(std::map<std::string, Variant> &&_map) : Ref(new _Map(_map)) {
        }

        _FORCE_INLINE_ Map(const Variant &var) : Ref(var) {
        }
        _FORCE_INLINE_ Map(const Reference &ref) : Ref(ref) {
        }
        _FORCE_INLINE_ void set(const std::string &key, const Variant &var) {
            get()->set(key, var);
        }

        _FORCE_INLINE_ Variant &operator[] (const std::string &key) {
            return get()->at(key);
        }
        _FORCE_INLINE_ Variant &operator[] (const char *key) {
            return get()->at(key);
        }

    CLASS_END
}

#endif //GSAV2_0_MAP_H
