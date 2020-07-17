//
//  Hash.h
//  hirender_iOS
//
//  Created by gen on 16/9/27.
//  Copyright © 2016年 gen. All rights reserved.
//

#ifndef Hash_h
#define Hash_h

#include <string>
#include "Define.h"

namespace gc {
//    _FORCE_INLINE_ uint64_t make_key(uint32_t hash, int32_t index) {
//        return (((uint64_t)hash & b32_mask) << 32)|((uint64_t)(index&b32_mask));
//    }
//    uint64_t h(const char *chs);
//    uint64_t h(const std::string &str);
    void *h(const char *chs);
    _FORCE_INLINE_ void* h(const std::string &str) {
        return h(str.c_str());
    }
//    const char *s(uint64_t hash);
}

#endif /* Hash_h */
