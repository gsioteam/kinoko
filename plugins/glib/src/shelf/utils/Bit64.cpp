//
// Created by gen on 6/25/2020.
//

#include "Bit64.h"
#include <bit64/bit64.h>

using namespace gc;
using namespace gs;
using namespace std;

#define B_SIZE 2048

std::string Bit64::encodeString(const std::string &str) {
    string ret;
    ret.resize(bit64_encode_size(str.size()));
    bit64_encode((const uint8_t *)str.data(), str.size(), (uint8_t *)ret.data());
    return ret;
}

std::string Bit64::encode(const gc::Ref<gc::Data> &data) {
    string ret;
    ret.resize(bit64_encode_size(data->getSize()));
    uint8_t buf[B_SIZE];
    vector<uint8_t> read_buf;
    size_t readed;
    while ((readed = data->read(buf, 1, B_SIZE)) > 0) {
        size_t s = read_buf.size();
        read_buf.resize(s + readed);
        memcpy(read_buf.data() + s, buf, readed);
    }
    bit64_encode(read_buf.data(), read_buf.size(), (uint8_t *)ret.data());
    return ret;
}

std::string Bit64::decodeString(const std::string &str) {
    string ret;
    ret.resize(bit64_decode_size(str.size()));
    bit64_decode((const uint8_t *)str.data(), str.size(), (uint8_t *)ret.data());
    return ret;
}

gc::Ref<gc::Data> Bit64::decode(const std::string &str) {
    vector<uint8_t> ret;
    ret.resize(bit64_decode_size(str.size()));
    bit64_decode((const uint8_t *)str.data(), str.size(), (uint8_t *)ret.data());
    return new_t(BufferData, ret.data(), ret.size());
}