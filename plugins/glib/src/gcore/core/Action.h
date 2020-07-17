//
//  Action.h
//  hirender_iOS
//
//  Created by gen on 16/9/27.
//  Copyright © 2016年 gen. All rights reserved.
//

#ifndef Action_h
#define Action_h

#include <stdlib.h>
#include <list>
#include <map>
#include "Reference.h"
#include "StringName.h"
#include "Variant.h"

namespace gc {
    class Callback;

    typedef std::list<Callback> CallbackStack;

    class EventManager {
        std::map<StringName, CallbackStack> events;

    public:
        struct EventHandler {
            StringName name;
            EventManager &manager;

            void operator<<(const Callback &);
            void operator>>(const Callback &);

            void call(const variant_vector &variants) const;

            template <typename ...Args>
            void operator() (Args && ...args) const {
                call(variant_vector{{args...}});
            }

        };

        _FORCE_INLINE_ EventHandler operator[] (const StringName &name) {
            return EventHandler{name, *this};
        }

    };
}

#endif /* Action_h */
