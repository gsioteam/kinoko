//
// Created by gen on 16/6/21.
//

#ifndef HI_RENDER_PROJECT_ANDROID_STRINGNAME_H
#define HI_RENDER_PROJECT_ANDROID_STRINGNAME_H

#include <unordered_map>
#include <vector>
#include "Hash.h"
#include "core_define.h"

namespace gc {
    class Class;
    class ClassDB;
    
    class StringName {
    BASE_FINAL_CLASS_DEFINE
        
    private:
        
        static StringName _null;

        union {
            void *ptr;
            char *str;
        } name;

        _FORCE_INLINE_ void updateString(const char *str) {
            name.ptr = h(str);
        }
        
    public:
        _FORCE_INLINE_ StringName() { name.ptr = NULL;}

        _FORCE_INLINE_ StringName &operator=(const StringName &other) {
            name = other.name;
            return *this;
        }
        _FORCE_INLINE_ StringName &operator=(const char *chs) {
            name.ptr = h(chs);
            return *this;
        }
        
        _FORCE_INLINE_ StringName(void *ptr) {
            name.ptr = ptr;
        }
        
        _FORCE_INLINE_ StringName(const StringName &other) {
            this->operator=(other);
        }

        _FORCE_INLINE_ StringName(const char *chs) {
            name.ptr = h(chs);
        }

        _FORCE_INLINE_ operator void *() const {
            return name.ptr;
        }
        _FORCE_INLINE_ const char *str() const {
            return name.str;
        }

        _FORCE_INLINE_ bool operator==(const StringName &other) const {
            return name.ptr == other.name.ptr;
        }

        _FORCE_INLINE_ bool operator<(const StringName &other) const {
            return name.ptr < other.name.ptr;
        }
        _FORCE_INLINE_ bool empty() const {
            return !name.ptr;
        }
        static const StringName &null() {
            return _null;
        }
    };
}


#endif //HI_RENDER_PROJECT_ANDROID_STRINGNAME_H
