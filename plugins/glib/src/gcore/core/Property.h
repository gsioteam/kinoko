//
// Created by gen on 16/9/1.
//

#ifndef VOIPPROJECT_PROPERTY_H
#define VOIPPROJECT_PROPERTY_H

#include <map>
#include "Method.h"
#include "core_define.h"

namespace gc {
    class Property {
        BASE_CLASS_DEFINE

        const Class     *clazz;
        const Method    *getter;
        const Method    *setter;
        StringName      *name;

        variant_map     *labels;

    public:
        _FORCE_INLINE_ Property() {}
        Property(const Class *clazz,
                 const char *name,
                 const Method *getter,
                 const Method *setter);
        Property(const Class *clazz,
                 const char *name,
                 const Method *getter,
                 const Method *setter,
                 const variant_map &labels);
        ~Property();

        _FORCE_INLINE_ const Class *getOwnerClass() const {
            return clazz;
        }

        _FORCE_INLINE_ const Method *getGetter() const {
            return getter;
        }
        _FORCE_INLINE_ const Method *getSetter() const {
            return setter;
        }
        _FORCE_INLINE_ const StringName &getName() const {
            return *name;
        }

        _FORCE_INLINE_ Variant get(Base *obj) const {
            return getter->call(obj, NULL, 0);
        }
        _FORCE_INLINE_ void set(Base *obj, const Variant &v) const {
            const Variant *vp[] = {&v};
            setter->call(obj, vp, 1);
        }
        _FORCE_INLINE_ const Variant &getLabel(const StringName &name) const {
            return getLabel(name);
        }
        _FORCE_INLINE_ bool hasLabel(const StringName &name) const {
            return hasLabel(name);
        }
    };
}

#endif //VOIPPROJECT_PROPERTY_H
