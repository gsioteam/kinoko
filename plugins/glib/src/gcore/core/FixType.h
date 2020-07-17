//
//  Integer.h
//  hirender_iOS
//
//  Created by gen on 16/6/2.
//  Copyright © 2016年 gen. All rights reserved.
//

#ifndef HICORE_INTEGER_H
#define HICORE_INTEGER_H

#include <string>
#include <sstream>
#include "Base.h"
#include "core_define.h"

namespace gc {
    
#define NUMBER_BASE(T, CT) BASE_FINAL_CLASS_DEFINE \
    CT(){} \
    INITIALIZE(CT, const T &v, \
               this->v = v; \
               ) \
    _FORCE_INLINE_ virtual operator char() const {return (char)v;} \
    _FORCE_INLINE_ virtual operator short() const {return (short)v;} \
    _FORCE_INLINE_ virtual operator int() const {return (int)v;} \
    _FORCE_INLINE_ virtual operator long() const {return (long)v;} \
    _FORCE_INLINE_ virtual operator long long() const {return (long long)v;} \
    _FORCE_INLINE_ virtual operator float() const {return (float)v;} \
    _FORCE_INLINE_ virtual operator double() const {return (double)v;} \
    _FORCE_INLINE_ virtual operator bool() const {return (bool)v;} \
    _FORCE_INLINE_ CT &operator+=(int _v) { \
        v += _v; \
        return *this; \
    } \
    _FORCE_INLINE_ CT &operator-=(int _v) { \
        v -= _v; \
        return *this; \
    } \
    _FORCE_INLINE_ CT &operator++() { \
        v++; \
        return *this; \
    } \
    _FORCE_INLINE_ CT &operator--() { \
        v--; \
        return *this; \
    } \
    _FORCE_INLINE_ CT operator+(T _v) { \
        return CT(v + _v); \
    } \
    _FORCE_INLINE_ CT operator-(T _v) { \
        return CT(v - _v); \
    } \
    
    template <typename T, typename CT>
    class FixType {
        T v;
    public:
        
        FixType(){}
        INITIALIZE(FixType, const T &v,
                   this->v = v;
                   )
        _FORCE_INLINE_ operator char() const {return (char)v;}
        _FORCE_INLINE_ operator short() const {return (short)v;}
        _FORCE_INLINE_ operator int() const {return (int)v;}
        _FORCE_INLINE_ operator long() const {return (long)v;}
        _FORCE_INLINE_ operator long long() const {return (long long)v;}
        _FORCE_INLINE_ operator float() const {return (float)v;}
        _FORCE_INLINE_ operator double() const {return (double)v;}
        _FORCE_INLINE_ operator bool () const {return (bool)v;}
        _FORCE_INLINE_ CT &operator+=(int _v) {
            v += _v;
            return *this;
        }
        _FORCE_INLINE_ CT &operator-=(int _v) {
            v -= _v;
            return *this;
        }
        _FORCE_INLINE_ CT &operator++() {
            v++;
            return *this;
        }
        _FORCE_INLINE_ CT &operator--() {
            v--;
            return *this;
        }
        _FORCE_INLINE_ CT operator+(T _v) {
            return CT(v + _v);
        }
        _FORCE_INLINE_ CT operator-(T _v) {
            return CT(v - _v);
        }
    };
    
    class Integer;
    class Long;
    class Float;
    class Double;
    
    class Char : public FixType<char, Char> {
        BASE_FINAL_CLASS_DEFINE
    public:
        _FORCE_INLINE_ Char():FixType(0){}
        _FORCE_INLINE_ Char(char c) : FixType(c){}
        
        _FORCE_INLINE_ std::string str() const {
            char ch[2];
            ch[0] = (char)*this;
            ch[1] = 0;
            return std::string(ch);
        }
    };
    
    class Short : public FixType<short, Short> {
        BASE_FINAL_CLASS_DEFINE
        
    public:
        _FORCE_INLINE_ Short():FixType(0){}
        _FORCE_INLINE_ Short(short s) : FixType(s){}
        
        _FORCE_INLINE_ std::string str() const {
            short ret = *this;
            std::stringstream ss;
            ss << ret;
            return ss.str();
        }
    };
    
    class Integer : public FixType<int, Integer> {
        BASE_FINAL_CLASS_DEFINE
        
    public:
        _FORCE_INLINE_ Integer():FixType(0){}
        _FORCE_INLINE_ Integer(int i) : FixType(i){}
        
        _FORCE_INLINE_ std::string str() const {
            int ret = *this;
            std::stringstream ss;
            ss << ret;
            return ss.str();
        }
    };
    
    class Long : public FixType<long, Long> {
        BASE_FINAL_CLASS_DEFINE
        
    public:
        _FORCE_INLINE_ Long():FixType(0){}
        _FORCE_INLINE_ Long(long l) : FixType(l){}
        
        _FORCE_INLINE_ std::string str() const {
            long ret = *this;
            std::stringstream ss;
            ss << ret;
            return ss.str();
        }
    };

    class LongLong : public FixType<long long, LongLong> {
        BASE_FINAL_CLASS_DEFINE
        
    public:
        _FORCE_INLINE_ LongLong():FixType(0){}
        _FORCE_INLINE_ LongLong(long long l) : FixType(l){}
        
        _FORCE_INLINE_ std::string str() const {
            long long ret = *this;
            std::stringstream ss;
            ss << ret;
            return ss.str();
        }
    };
    
    class Float : public FixType<float, Float> {
        BASE_FINAL_CLASS_DEFINE
        
    public:
        _FORCE_INLINE_ Float():FixType(0){}
        _FORCE_INLINE_ Float(float f) : FixType(f){}
        
        _FORCE_INLINE_ std::string str() const {
            float ret = *this;
            std::stringstream ss;
            ss << ret;
            return ss.str();
        }
    };

    class Double : public FixType<double, Double> {
        BASE_FINAL_CLASS_DEFINE
        
    public:
        _FORCE_INLINE_ Double():FixType(0){}
        _FORCE_INLINE_ Double(double d) : FixType(d){}
        
        _FORCE_INLINE_ std::string str() const {
            double ret = *this;
            std::stringstream ss;
            ss << ret;
            return ss.str();
        }
    };

    class Boolean : public FixType<bool, Boolean> {
    BASE_FINAL_CLASS_DEFINE

    public:
        _FORCE_INLINE_ Boolean():FixType(0){}
        _FORCE_INLINE_ Boolean(double d) : FixType(d){}

        _FORCE_INLINE_ std::string str() const {
            return (bool)(*this) ? "true" : "false";
        }
    };

    class Null {
        BASE_FINAL_CLASS_DEFINE
    };
}

#endif //HICORE_INTEGER_H
