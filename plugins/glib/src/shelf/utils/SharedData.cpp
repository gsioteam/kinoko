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
const std::string shared::SETTING_KEY = "SETTING:";
const std::vector<uint8_t> shared::public_key{2,169,116,121,28,94,121,148,224,164,101,4,129,150,179,221,230,79,31,104,57,165,189,188,150,139,234,217,84,155,201,149,10,};

std::time_t gs::getTimeStamp() {
    std::chrono::time_point<std::chrono::system_clock,std::chrono::milliseconds> tp = std::chrono::time_point_cast<std::chrono::milliseconds>(std::chrono::system_clock::now());//获取当前时间点
    std::time_t timestamp =  tp.time_since_epoch().count(); //计算距离1970-1-1,00:00的时间长度
    return timestamp;
}

std::string gs::calculatePath(const std::string &base_path, const std::string &src) {
    int start = 0, end = 0;
    while (true) {
        end = src.find("/", start);
    }
}