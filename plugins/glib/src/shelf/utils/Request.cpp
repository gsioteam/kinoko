//
// Created by Gen2 on 2019-11-17.
//

#include "Request.h"
#include "Platform.h"
#include <sstream>

using namespace gs;
using namespace gc;
using namespace std;

ref_list Request::requests;

const gc::StringName Request::GET("GET");
const gc::StringName Request::POST("POST");
const gc::StringName Request::DELETE("DELETE");
const gc::StringName Request::PUT("PUT");
const gc::StringName Request::HEADER("HEADER");
const gc::StringName Request::OPTIONS("OPTIONS");

std::string& Request::trim(std::string &s)
{
    if (s.empty())
    {
        return s;
    }

    s.erase(0,s.find_first_not_of("\t\n\v\f\r "));
    s.erase(s.find_last_not_of("\t\n\v\f\r ") + 1);
    return s;
}

size_t Request::writeHeader(char *buffer, size_t size, size_t nitems, void *userdata) {
    Request *request = (Request *)userdata;
    string data(buffer, size * nitems);

    size_t idx = data.find(':');
    if (idx < data.size()) {
        string key = data.substr(0, idx);
        string value = data.substr(idx + 1);
        trim(key);
        trim(value);
        request->response_headers[key] = value;
    }
    return size * nitems;
}

size_t Request::writeBody(char *buffer, size_t size, size_t nitems, void *userdata) {
    Request *request = (Request *)userdata;
    MultiData *data = NULL;
    if (!request->response_body) {
        data = new MultiData;
        request->response_body = data;
    }else {
        data = request->response_body->cast_to<MultiData>();
    }
    data->write((uint8_t *)buffer, size, nitems);
    return size * nitems;
}

int Request::process(void *clientp, curl_off_t dltotal, curl_off_t dlnow, curl_off_t ultotal, curl_off_t ulnow) {
    Request *request = (Request *)clientp;
    if (request->canceled) return -2;
    request->download_total = dltotal;
    request->download_now = dlnow;
    request->upload_total = ultotal;
    request->upload_now = ulnow;
    if (request->on_progress) {
        Ref<Request> req(request);
        Platform::doOnMainThread(C([=](const Ref<Request> &req){
            req->on_progress(dltotal, dlnow, ultotal, ulnow);
        }));
    }
    return 0;
}

int Request::oldProcess(void *clientp, double dltotal, double dlnow, double ultotal, double ulnow) {
    return process(clientp, (curl_off_t)dltotal, (curl_off_t)dlnow, (curl_off_t)ultotal, (curl_off_t)ulnow);
}

Request::Request() {
}

void Request::start() {
    if (fired) {
        LOG(e, "Request is already fired!");
        return;
    }
    fired = true;
    thread th(bind(&Request::run, this));
    th.detach();
    requests.push_back(this);
}

void Request::run() {

    vector<uint8_t> body_data;
    CURL *cu = curl_easy_init();
    curl_easy_setopt(cu, CURLOPT_URL, url.c_str());
    if (method == GET) {

    }else if (method == POST) {
        curl_easy_setopt(cu, CURLOPT_POST, 1L);

        if (body->instanceOf(BufferData::getClass())) {
            BufferData *buf = body->cast_to<BufferData>();
            curl_easy_setopt(cu, CURLOPT_POSTFIELDS, buf->getBuffer());
            curl_easy_setopt(cu, CURLOPT_POSTFIELDSIZE, (long)buf->getSize());
        }else {
            body_data = body->readAll();
            curl_easy_setopt(cu, CURLOPT_POSTFIELDS, body_data.data());
            curl_easy_setopt(cu, CURLOPT_POSTFIELDSIZE, (long)body_data.size());
        }
    }else {
        curl_easy_setopt(cu, CURLOPT_CUSTOMREQUEST, method.str());
    }

    struct curl_slist *list = NULL;
    for (auto it = headers.begin(), _e = headers.end(); it != _e; ++it) {
        string header_tmp = it->first + ": " + it->second;
        list = curl_slist_append(list, header_tmp.c_str());
    }

    if (list) {
        curl_easy_setopt(cu, CURLOPT_HTTPHEADER, list);
    }



    curl_easy_setopt(cu, CURLOPT_HEADERFUNCTION, Request::writeHeader);
    curl_easy_setopt(cu, CURLOPT_HEADERDATA, this);

    curl_easy_setopt(cu, CURLOPT_WRITEFUNCTION, Request::writeBody);
    curl_easy_setopt(cu, CURLOPT_WRITEDATA, this);
#if LIBCURL_VERSION_NUM >= 0x072000
    curl_easy_setopt(cu, CURLOPT_XFERINFOFUNCTION, &Request::process);
    curl_easy_setopt(cu, CURLOPT_XFERINFODATA, this);
#else
    curl_easy_setopt(cu, CURLOPT_PROGRESSFUNCTION, &Request::oldProcess);
    curl_easy_setopt(cu, CURLOPT_PROGRESSDATA, this);
#endif
    CURLcode res = curl_easy_perform(cu);
    if (res != CURLE_OK) {
        error = curl_easy_strerror(res);
    }
    Platform::doOnMainThread(C(Request::requestComplete, this));

    if (list) curl_slist_free_all(list);
    curl_easy_cleanup(cu);
}

void Request::requestComplete(const gc::Ref<gs::Request> &req) {
    if (req->canceled) return;
    requests.remove(req);
    req->on_complete();
}

Request::~Request() {
}
