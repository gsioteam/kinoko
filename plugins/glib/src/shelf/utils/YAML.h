//
// Created by gen on 8/12/2020.
//

#ifndef ANDROID_YAML_H
#define ANDROID_YAML_H

#include <core/Ref.h>
#include "../gs_define.h"

namespace gs {
    class tokenizer;
    class yaml {
    public:
        enum Type {
            None,
            Value,
            Array,
            Map
        };
        class _yaml {
            std::string key;
            yaml *_target;

        public:
            _yaml(const std::string &key, yaml *tar) : key(key), _target(tar) {
            }

            _yaml &operator=(const yaml &other);
            yaml &operator=(yaml &other);
            operator yaml() const;

            operator bool() const {
                return bool(this->operator yaml());
            }
            operator int() const {
                return int(this->operator yaml());
            }
            operator long() const {
                return long(this->operator yaml());
            }
            operator long long() const {
                return (long long)(this->operator yaml());
            }
            operator float() const {
                return (float)(this->operator yaml());
            }

            operator std::string() const {
                return this->operator yaml();
            }
        };

    private:

        Type type = None;
        std::string value;
        std::list<yaml> array;
        std::map<std::string, yaml> map;

        static yaml parse_map(tokenizer &tokenizer);
        static yaml parse_array(tokenizer &tokenizer);
        static yaml parse_node(tokenizer &tokenizer);

        friend class _yaml;

    public:

        static yaml parse(const std::string &str);
        yaml(Type type = None);

        yaml &operator << (const yaml &val);
        _yaml operator[](const std::string &key);
        _yaml operator[](const char *key) {
            return this->operator[](std::string(key));
        }
        size_t size() const;

        yaml(const char *str);

        bool is_boolean() const;
        bool is_number() const;
        bool is_map() const {
            return type == Map;
        }
        bool is_array() const {
            return type == Array;
        }

        bool has(const std::string &key) const;

        operator bool() const;
        operator int() const;
        operator long() const;
        operator long long() const;
        operator float() const;

        operator std::string() const;
    };

    CLASS_BEGIN_N(YAML, gc::Object)

    public:

        static gc::Variant parse(const std::string &str);

    CLASS_END
}


#endif //ANDROID_YAML_H
