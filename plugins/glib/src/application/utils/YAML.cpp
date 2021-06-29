//
// Created by gen on 8/12/2020.
//

#include "YAML.h"
#include <yaml.h>
#include <core/Map.h>
#include <core/Array.h>
#include <core/String.h>
#include <set>
#include <libyaml/include/yaml.h>

using namespace gs;
using namespace gc;
using namespace std;

namespace gs {
    namespace cons {
        std::string sign("+-");
        set<std::string> null_set = {
                "null",
                "~",
                "NULL"
        };
        set<std::string> true_set = {
                "y",
                "yes",
                "true",
                "on",
                "Y",
                "YES",
                "TRUE",
                "ON"
        };
        set<std::string> false_set = {
                "n",
                "no",
                "false",
                "off",
                "N",
                "NO",
                "FALSE",
                "OFF"
        };
        set<string> inf_set = {
                ".inf",
                "+.inf",
                ".INF",
                "+.INF"
        };
        set<string> neg_inf_set = {
                "-.inf",
                "-.INF"
        };
        set<string> nan_set = {
                ".nan",
                ".NAN"
        };

        set<char> bit_set = {
                '0',
                '1',
                '_'
        };
        set<char> hex_set = {
                '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
                'a', 'b', 'c', 'd', 'e', 'f', 'A', 'B', 'C', 'D', 'E', 'F'
        };

        set<char> number_set = {
                '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
        };

        bool checkStr(string::iterator begin, const string::iterator &end, const set<char> &test) {
            for (; begin != end; ++begin) {
                if (!test.count(*begin)) return false;
            }
            return true;
        }
        bool isNumber(string::iterator begin, const string::iterator &end) {
            bool hasDot = false;
            for (; begin != end; ++begin) {
                char ch = *begin;
                if (ch == '.') {
                    if (hasDot) return false;
                    else hasDot = true;
                } else {
                    if (!number_set.count(ch)) return false;
                }
            }
            return true;
        }

        bool isBit(string::iterator begin, const string::iterator &end) {
            if (*begin != '0') return false;
            ++begin;
            if (*begin != 'b' && *begin != 'B') return false;
            ++begin;
            return checkStr(begin, end, bit_set);
        }

        bool isHex(string::iterator begin, const string::iterator &end) {
            if (*begin != '0') return false;
            ++begin;
            if (*begin != 'x' && *begin != 'X') return false;
            ++begin;
            return checkStr(begin, end, hex_set);
        }
    }

    class tokenizer {
        yaml_parser_t parser;
        yaml_event_t event;

    public:
        tokenizer(const string &str) {
            yaml_parser_initialize(&parser);
            yaml_parser_set_input_string(&parser, (const uint8_t *)str.data(), str.size());
            event.type = YAML_NO_EVENT;
        }

        bool next() {
            return yaml_parser_parse(&parser, &event);
        }

        yaml_event_type_t current() {
            return event.type;
        }

        const char *value() {
            if (event.type == YAML_SCALAR_EVENT) {
                return (const char *)event.data.scalar.value;
            }
            return nullptr;
        }
    };
}

yaml::_yaml & yaml::_yaml::operator=(const yaml &other) {
    if (_target->type == Map) {
        _target->map[key] = other;
    }
    return *this;
}

yaml & yaml::_yaml::operator=(yaml &other) {
    if (_target->type == Map) {
        _target->map[key] = other;
    }
    return other;
}

yaml::_yaml::operator yaml() const {
    if (_target->type == Map) {
        auto it = _target->map.find(key);
        if (it != _target->map.end()) {
            return it->second;
        }
    }
    return yaml();
}

yaml::yaml(gs::yaml::Type type) : type(type) {
}

yaml::yaml(const char *str) : yaml(Type::Value) {
    value = str;
}

yaml yaml::parse_map(tokenizer &tokenizer) {
    yaml current(Map);
    while (true) {

        switch (tokenizer.current()) {
            case YAML_SCALAR_EVENT: {
                string key = tokenizer.value() ? tokenizer.value() : "";
                tokenizer.next();
                current[key] = parse_node(tokenizer);
                break;
            }
            case YAML_MAPPING_END_EVENT: {
                return current;
            }
            default:
                break;
        }
        if (tokenizer.current() == YAML_DOCUMENT_END_EVENT || !tokenizer.next()) break;
    }
    return current;
}

yaml yaml::parse_array(tokenizer &tokenizer) {
    yaml current(Array);
    while (true) {

        switch (tokenizer.current()) {
            case YAML_SEQUENCE_END_EVENT: {
                return current;
            }
            default: {
                current << parse_node(tokenizer);
                break;
            }
        }

        if (tokenizer.current() == YAML_DOCUMENT_END_EVENT || !tokenizer.next()) break;
    }
    return current;
}

yaml yaml::parse_node(gs::tokenizer &tokenizer) {
    while (true) {
        switch (tokenizer.current()) {
            case YAML_SCALAR_EVENT: {
                return yaml(tokenizer.value());
            }
            case YAML_MAPPING_START_EVENT: {
                return parse_map(tokenizer);
            }
            case YAML_SEQUENCE_START_EVENT: {
                return parse_array(tokenizer);
            }
            default:
                break;
        }
        if (tokenizer.current() == YAML_DOCUMENT_END_EVENT || !tokenizer.next()) break;
    }
    return yaml();
}

yaml & yaml::operator<<(const yaml &val) {
    if (type == Array) {
        array.push_back(val);
    }
    return *this;
}

yaml::_yaml yaml::operator[](const std::string &key) {
    return _yaml(key, this);
}

yaml yaml::parse(const std::string &str) {

    gs::tokenizer tokenizer(str);

    yaml doc;

    while (true) {
        tokenizer.next();

        switch (tokenizer.current()) {
            case YAML_DOCUMENT_START_EVENT: {
                doc = parse_node(tokenizer);
                break;
            }

        }
        if (tokenizer.current() == YAML_DOCUMENT_END_EVENT) break;
    }
    return doc;
}

bool yaml::is_boolean() const {
    if (type == Value) {
        return cons::true_set.count(value) || cons::false_set.count(value);
    }
    return false;
}

bool yaml::is_number() const {
    if (type == Value) {
        if (cons::inf_set.count(value) ||
        cons::neg_inf_set.count(value) ||
        cons::nan_set.count(value)) {
            return true;
        }
        auto begin = value.begin();
        auto end = value.end();
        if (*begin == '+' || *begin == '-') ++begin;

    }
    return false;
}

bool yaml::has(const std::string &key) const {
    if (type == Map) {
        return map.find(key) != map.end();
    }
    return false;
}

size_t yaml::size() const {
    switch (type) {
        case Array: return array.size();
        case Map: return map.size();
        default: return 0;
    }
}

yaml::operator bool() const {
    switch (type) {
        case Array: return !array.empty();
        case Map: return !map.empty();
        default: {
            if (cons::true_set.count(value)) {
                return true;
            } else if (cons::false_set.count(value)) {
                return false;
            } else {
                return !value.empty();
            }
        }
    }
}

yaml::operator int() const {
    if (type == Value) {
        return atoi(value.c_str());
    }
    return 0;
}

yaml::operator long() const {
    if (type == Value) {
        return atol(value.c_str());
    }
    return 0;
}

yaml::operator long long() const {
    if (type == Value) {
        return atoll(value.c_str());
    }
    return 0;
}

yaml::operator float() const {
    if (type == Value) {
        return atof(value.c_str());
    }
    return 0;
}

yaml::operator std::string() const {
    if (type == Value) {
        return value;
    }
    return string();
}

gc::Variant YAML::parse(const std::string &str) {
    yaml_parser_t parser;
    yaml_parser_initialize(&parser);
    yaml_parser_set_input_string(&parser, (const uint8_t *)str.data(), str.size());
    Variant result;
    while (true) {
        yaml_event_t event;
        if (!yaml_parser_parse(&parser, &event)) {
            return Variant::null();
        }
        Map currentMap;
        Array currentArray;
        yaml_event_type_t currentType = YAML_NO_EVENT;
        std::string key;

        function<void(const Variant &)> send = [&](const Variant &var) {
            switch (currentType) {
                case YAML_MAPPING_START_EVENT: {
                    if (key.empty()) {
                        key = var.str();
                    } else {
                        currentMap[key] = var;
                    }
                    break;
                }
                case YAML_SEQUENCE_START_EVENT: {
                    currentArray.push_back(var);
                    break;
                }
                default:
                    break;
            }
        };
        switch (event.type) {
            case YAML_DOCUMENT_START_EVENT: {
                break;
            }
            case YAML_DOCUMENT_END_EVENT: {
                switch (currentType) {
                    case YAML_MAPPING_START_EVENT: {
                        result = currentMap;
                        break;
                    }
                    case YAML_SEQUENCE_START_EVENT: {
                        result = currentArray;
                        break;
                    }
                    default:
                        break;
                }
                break;
            }
            case YAML_MAPPING_START_EVENT: {
                currentType = event.type;
                currentMap = Map();
                break;
            }
            case YAML_MAPPING_END_EVENT: {
                send(currentMap);
                break;
            }
            case YAML_SEQUENCE_START_EVENT: {
                currentType = event.type;
                currentArray = Array();
                break;
            }
            case YAML_SEQUENCE_END_EVENT: {
                send(currentArray);
                break;
            }
            case YAML_SCALAR_EVENT: {
                send(event.data.scalar.value);
                break;
            }
            case YAML_STREAM_START_EVENT: {
                break;
            }
            case YAML_STREAM_END_EVENT: {
                break;
            }
            default: {
                break;
            }
        }
        if (event.type == YAML_DOCUMENT_END_EVENT) break;
    }
    return result;
}