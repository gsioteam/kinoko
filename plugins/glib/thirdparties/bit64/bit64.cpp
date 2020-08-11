//
// Created by Gen2 on 2019-03-08.
//

#include <math.h>
#include <stddef.h>
#include <stdlib.h>
#include "bit64.h"
#include <unordered_map>
#include <vector>

using namespace std;

typedef unsigned char uint8_t;

const int bit64_SIZE = 64;
const int bit64_KEY = 32;

const int bit64_SPAN = 4;
const float bit64_COUNT = (42.0f/bit64_SPAN);

struct bit64_map_t {
    vector<uint8_t> c_map;
    uint8_t rev_map[256];
};

bit64_map_t bit64_map;

void bit64_makeIndex() {
    vector<char> res;
    char from, end, i;
    int off = 0;
    from = '0'; end = '9';
    for (i = from; i <= end; ++i) {
        res.push_back(i);
    }
    from = 'a'; end = 'z';
    for (i = from; i <= end; ++i) {
        res.push_back(i);
    }
    from = 'A'; end = 'Z';
    for (i = from; i <= end; ++i) {
        res.push_back(i);
    }
    res.push_back('_');
    res.push_back('-');
    off = bit64_KEY;
    while (!res.empty()) {
        off = (int)(off % res.size());
        char ch = res[off];
        res.erase(res.begin() + (off++));
        bit64_map.rev_map[ch] = (uint8_t)bit64_map.c_map.size();
        bit64_map.c_map.push_back(ch);
    }
}

uint8_t bit64_hex64(int num) {
    if (num >= 0 && num < bit64_SIZE) {
        if (bit64_map.c_map.size() == 0) {
            bit64_makeIndex();
        }
        return bit64_map.c_map[num];
    }
    return 0;
}

char bit64_hex64rev(char ch) {
    if (bit64_map.c_map.size() == 0) {
        bit64_makeIndex();
    }
    return bit64_map.rev_map[ch];
}

unsigned long bit64_calculate_seed(const char *hash) {
    int off = (bit64_hex64rev(hash[0])+1) % bit64_SPAN;
    unsigned long res = 0;
    for (int i = 0; i < bit64_COUNT; ++i) {
        int n = bit64_hex64rev(hash[i * bit64_SPAN + off]);
        res = (res << 1) + n;
    }
    return res;
}

extern "C" unsigned long bit64_encode_size(unsigned long buffer_length) {
    return (unsigned long)ceilf(buffer_length * 4.0f / 3.0f);
}
extern "C" unsigned long bit64_encode(const uint8_t *buffer, unsigned long buffer_length, uint8_t *result) {
    int tb = 0;
    uint32_t tmp = 0;
    unsigned long res_len = 0;
    for (int i = 0, t = (int)buffer_length; i < t; ++i) {
        uint8_t b = buffer[i];
        tmp = tmp | (b << tb);
        tb += 8;
        while (tb >= 6) {
            uint8_t l = (uint8_t)(tmp & (bit64_SIZE - 1));
            tmp = tmp >> 6;
            tb -= 6;
            l = bit64_hex64(l);
            result[res_len++] = l;
        }
    }

    while (tb > 0) {
        uint8_t l = (uint8_t)(tmp & (bit64_SIZE - 1));
        tmp = tmp >> 6;
        tb -= 6;
        l = bit64_hex64(l);
        result[res_len++] = l;
    }
    return res_len;
}

extern "C" unsigned long bit64_decode_size(unsigned long buffer_length) {
    return (unsigned long)ceilf(buffer_length * 3.0f / 4.0f);
}
extern "C" unsigned long bit64_decode(const uint8_t *buffer, unsigned long buffer_length, uint8_t *result) {
    int tb = 0;
    uint32_t tmp = 0;
    unsigned long res_len = 0;
    for (int i = 0, t = (int)buffer_length; i < t; ++i) {
        uint8_t ch = buffer[i];
        tmp = tmp | (bit64_hex64rev(ch) << tb);
        tb += 6;
        while (tb >= 8) {
            uint8_t l = (uint8_t)(tmp & 0xff);
            tmp = tmp >> 8;
            tb -= 8;
            result[res_len++] = l;
        }
    }
    while (tb > 0) {
        uint8_t l = (uint8_t)(tmp & 0xff);
        tmp = tmp >> 8;
        tb -= 8;
        if (l > 0) {
            result[res_len++] = l;
        }
    }
    return res_len;
}



extern "C" void bit64_encrypt_index(const char *hash, int idx, char *result) {
    unsigned long seed = bit64_calculate_seed(hash);
    size_t radix = bit64_map.c_map.size();
    unsigned long tmp = seed + idx * 1023;
    int res_len = 0;
    while (tmp > 0) {
        size_t i = tmp % radix;
        result[res_len++] = bit64_map.c_map[i];
        tmp = tmp / radix;
    }
    result[res_len] = 0;
}