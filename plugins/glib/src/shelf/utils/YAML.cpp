//
// Created by gen on 8/12/2020.
//

#include "YAML.h"
#include <yaml.h>
#include <core/Map.h>
#include <core/Array.h>
#include <core/String.h>
#include <set>

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

        bool checkStr(string::iterator begin, const string::iterator &end, const set<char> &test) {
            for (; begin != end; ++begin) {
                if (!test.count(*begin)) return false;
            }
            return true;
        }
    }
}

gc::Variant YAML::parseValue(const gc::Variant &value) {
    if (value.getTypeClass() == _String::getClass()) {
        std::string s = value.str();
        if (cons::null_set.count(s)) {
            return Variant::null();
        } else if (cons::true_set.count(s)) {
            return true;
        } else if (cons::false_set.count(s)) {
            return false;
        } else if (cons::inf_set.count(s)) {
            return INT64_MAX;
        } else if (cons::neg_inf_set.count(s)) {
            return INT64_MIN;
        } else if (cons::nan_set.count(s)) {
            return NAN;
        } else if (s.length() > 2 &&
        ((cons::sign.find(s[0]) >= 0 && s[1] == '0' && s[2] == 'b' &&
        cons::checkStr(s.begin() + 3, s.end(), cons::bit_set)) ||
        (s[0] == '0' && s[1] == 'b' &&
        cons::checkStr(s.begin() + 2, s.end(), cons::bit_set)))) {
            int sign = 1;
            size_t  off = 0;
            if (s[0] == '+') {
                off = 1;
            } else if (s[0] == '-') {
                off = 1;
                sign = -1;
            }
            off += 2;
            uint64_t res = 0;
            for (size_t t = s.length(); off < t; ++off) {
                char ch = s[off];
                if (ch == '_') continue;
                res <<= 1;
                if (ch == '1') res |= 1;
            }
            return sign * res;
        }
    } else {
        return value;
    }
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
                        currentMap[key] = parseValue(var);
                    }
                    break;
                }
                case YAML_SEQUENCE_START_EVENT: {
                    currentArray.push_back(parseValue(var));
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

            }
        }
        if (event.type == YAML_DOCUMENT_END_EVENT) break;
    }
    return result;
}