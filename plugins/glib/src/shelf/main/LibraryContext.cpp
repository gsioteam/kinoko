//
// Created by gen on 8/13/2020.
//

#include "LibraryContext.h"
#include "../utils/YAML.h"
#include "../utils/SharedData.h"
#include <secp256k1.h>
#include <sha256.h>
#include <bit64/bit64.h>
#include "../models/GitLibrary.h"

using namespace gs;
using namespace gc;

LibraryContext::LibraryContext() {
    data = GitLibrary::allLibraries();
}

bool LibraryContext::parseLibrary(const std::string &body) {
    yaml y_data = yaml::parse(body);
    if (y_data.is_map()) {
        std::string token = y_data["token"];
        std::string url = y_data["src"];
        if (url.empty() || token.empty()) {
            return false;
        }

        if (isMatch(token, url, this->token)) {
            this->token = token;
            bool ignore = y_data["ignore"];
            if (!ignore) {
                Ref<GitLibrary> lib = find(url);
                if (!lib) {
                    lib = new GitLibrary;
                    data->push_back(lib);
                }
                lib->setTitle(y_data["title"]);
                lib->setDate(getTimeStamp());
                lib->setUrl(url);
                lib->setIcon(y_data["icon"]);
                lib->setToken(token);
                lib->save();
            }
            return true;
        }
    }
    return false;
}

bool LibraryContext::insertLibrary(const std::string &url) {
    Ref<GitLibrary> lib = find(url);
    if (!lib) {
        lib = new GitLibrary;
        lib->setUrl(url);
        data->push_back(lib);
    }
    lib->setDate(getTimeStamp());
    lib->save();
    return true;
}

bool LibraryContext::removeLibrary(const std::string &url) {
    if (data) {
        for (int i = 0; i < data->size(); ++i) {
            Ref<GitLibrary> lib = data->get(i);
            if (lib->getUrl() == url) {
                data->remove(lib);
                lib->remove();
                return true;
            }
        }
    }
    return false;
}

bool LibraryContext::isMatch(const std::string &token, const std::string &url, const std::string &prev) {
    sha256_context sha256_ctx;
    sha256_init(&sha256_ctx);
    if (!prev.empty()) {
        b8_vector data;
        data.resize(bit64_decode_size(prev.size()));
        size_t d_size = bit64_decode((const uint8_t *)prev.data(), prev.size(), data.data());
        sha256_hash(&sha256_ctx, data.data(), d_size);
    }
    sha256_hash(&sha256_ctx, (uint8_t *)url.data(), url.size());
    uint8_t sha256_res[32];
    sha256_done(&sha256_ctx, sha256_res);

    secp256k1_context *secp256k1_ctx = secp256k1_context_create(SECP256K1_CONTEXT_VERIFY);
    secp256k1_pubkey pubkey;
    if (!secp256k1_ec_pubkey_parse(secp256k1_ctx, &pubkey, shared::public_key.data(), shared::public_key.size())) {
        return false;
    }
    uint8_t test[65];
    size_t test_size = 65;
    secp256k1_ec_pubkey_serialize(secp256k1_ctx, test, &test_size, &pubkey, SECP256K1_EC_UNCOMPRESSED);
    secp256k1_ecdsa_signature signature;
    size_t dec_size = bit64_decode_size(token.size());
    if (dec_size != 64 && dec_size != 65) {
        return false;
    }
    uint8_t *buf = (uint8_t *)malloc(dec_size);
    dec_size = bit64_decode((const uint8_t *)token.data(), token.size(), buf);
    if (dec_size != 64) {
        free(buf);
        return false;
    }
    secp256k1_ecdsa_signature_parse_compact(secp256k1_ctx, &signature, buf);
    free(buf);
    return secp256k1_ecdsa_verify(secp256k1_ctx, &signature, sha256_res, &pubkey);
}

gc::Ref<GitLibrary> LibraryContext::find(const std::string &url) {
    for (auto it = data->begin(), _e = data->end(); it != _e; ++it) {
        Ref<GitLibrary> lib = *it;
        if (lib->getUrl() == url) {
            return lib;
        }
    }
    return Ref<GitLibrary>::null();
}

void LibraryContext::reset() {
    token.clear();
}