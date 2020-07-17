//
// Created by gen on 16/7/5.
//

#ifndef HI_RENDER_PROJECT_ANDROID_STRING_H
#define HI_RENDER_PROJECT_ANDROID_STRING_H

#include "Base.h"
#include <string>
#include "Ref.h"
#include "core_define.h"

namespace gc {
    CLASS_BEGIN_N(_String, Object)
    private:
        std::string content;

    public:
        _FORCE_INLINE_ _String() {}
        _FORCE_INLINE_ _String(const char *content) {
            if (content) this->content = content;
        }
        _FORCE_INLINE_ _String(std::string content) {
            this->content = content;
        }
        _FORCE_INLINE_ _String(const _String &other) {
            this->content = other.content;
        }
        _FORCE_INLINE_ operator std::string() {
            return content;
        }
        _FORCE_INLINE_ operator const std::string() const {
            return content;
        }
        _FORCE_INLINE_ virtual std::string str() const {
            return content;
        }
        _FORCE_INLINE_ _String &operator=(const std::string &str) {
            content = str;
            return *this;
        }
        _FORCE_INLINE_ _String &operator=(const _String &other) {
            content = other.content;
            return *this;
        }
        _FORCE_INLINE_ const char *c_str() {
            return content.c_str();
        }

    CLASS_END

    class String : public Ref<_String> {

            _String *target() {
                if (!get()) {
                    Ref<_String>::operator=(new _String());
                }
                return get();
            }

    public:
        _FORCE_INLINE_ String() {}

        _FORCE_INLINE_ String(const char *content) : Ref(new _String(content)) {
        }

        _FORCE_INLINE_ String(std::string content) : Ref(new _String(content)) {
        }

        _FORCE_INLINE_ String(const Reference &ref) : Ref(ref) {
        }

        _FORCE_INLINE_ operator std::string() {
            return get() ? get()->str() : std::string();
        }

        _FORCE_INLINE_ operator const std::string() const {
            return get() ? get()->str() : std::string();
        }

        _FORCE_INLINE_ std::string str() const {
            return get() ? get()->str() : std::string();
        }

        _FORCE_INLINE_ String &operator=(const std::string &str) {
            target()->operator=(str);
            return *this;
        }

        _FORCE_INLINE_ String &operator=(const char * str) {
            target()->operator=(_String(str));
            return *this;
        }

        _FORCE_INLINE_ String &operator=(const _String &other) {
            target()->operator=(other);
            return *this;
        }

    };
}


#endif //HI_RENDER_PROJECT_ANDROID_STRING_H
