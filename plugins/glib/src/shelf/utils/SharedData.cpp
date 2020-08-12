//
// Created by gen on 6/13/2020.
//

#include "SharedData.h"

using namespace gs;

std::string shared::root_path;
bool shared::is_debug_mode = false;
std::string shared::debug_path;

std::string shared::repo_path(bool ignore_debug) {
    return (is_debug_mode && !ignore_debug) ? debug_path : (root_path + "/repo");
}

const std::string shared::MAIN_PROJECT_KEY = "MAIN_PROJECT";
const std::string shared::HOME_PAGE_LIST = "HOME_PAGE_LIST:";
const std::vector<uint8_t> shared::public_key{2,169,116,121,28,94,121,148,224,164,101,4,129,150,179,221,230,79,31,104,57,165,189,188,150,139,234,217,84,155,201,149,10,};