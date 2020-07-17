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