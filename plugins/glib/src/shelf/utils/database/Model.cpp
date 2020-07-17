//
//  Model.cpp
//  hirender_iOS
//
//  Created by gen on 12/05/2017.
//  Copyright © 2017 gen. All rights reserved.
//

#include "Model.h"
#include "../Platform.h"

using namespace gs;
using namespace gc;
using namespace std;

const ref_vector &Query::res() {
    if (changed) {
        find();
        changed = false;
    }
    return _results;
}

Array Query::results() {
    const ref_vector &r = res();
    variant_vector vs;
    for (auto it = r.begin(), _e = r.end(); it != _e; ++it) {
        vs.push_back(*it);
    }
    return vs;
}

//void Database::fixedStep(Renderer *renderer, Time delta) {
//    mtx.lock();
//    if (queue.size())
//        checkQueue();
//    mtx.unlock();
//}

void Database::exce(const std::string &statement, variant_vector *params, const Callback &callback) {
    mtx.lock();
    queue.push_back(new QueueItem(statement, params, callback));
    mtx.unlock();
    checkQueue();
}

void Database::queueExce(const std::string &statement, variant_vector *params, const Callback &callback) {
    mtx.lock();
    queue.push_back(new QueueItem(statement, params, callback));
    onCheckAction();
    mtx.unlock();
}

void Database::checkQueue() {
    mtx.lock();
    wait_action = false;
    if (queue.size()) {
        begin();
        for (auto it = queue.begin(), _e = queue.end(); it != _e; ++it) {
            QueueItem *item = (Database::QueueItem*)*it;
            action(item->statement, &item->params, item->callback);
            delete item;
        }
        queue.clear();
        end();
    }
    mtx.unlock();
}

void Database::onCheckAction() {
    if (!wait_action) {
        wait_action = true;
        function<void()> fn = bind(&Database::checkQueue, this);
        Platform::startTimer(C(fn), 0, false);
    }
}

Database::~Database() {
    if (queue.size()) {
        for (auto it = queue.begin(), _e = queue.end(); it != _e; ++it) {
            QueueItem *item = (Database::QueueItem*)*it;
            delete item;
        }
    }
}
