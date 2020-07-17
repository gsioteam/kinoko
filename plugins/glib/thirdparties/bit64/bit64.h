//
// Created by Gen2 on 2019-03-08.
//

#ifndef NUP2P_BIT64_H
#define NUP2P_BIT64_H

#ifdef __cplusplus
extern "C" {
#endif

unsigned long bit64_encode_size(unsigned long buffer_length);
unsigned long bit64_encode(const unsigned char *buffer, unsigned long buffer_length, unsigned char *result);

unsigned long bit64_decode_size(unsigned long buffer_length);
unsigned long bit64_decode(const unsigned char *buffer, unsigned long buffer_length, unsigned char *result);

void bit64_encrypt_index(const char *hash, int idx, char *result);

#ifdef __cplusplus
}
#endif

#endif //NUP2P_BIT64_H
