//
//  DBMaker.cpp
//  hirender_iOS
//
//  Created by mac on 2017/5/13.
//  Copyright © 2017年 gen. All rights reserved.
//

#include "DBMaker.h"
#include "SQLite.h"
#include "Model.h"

using namespace gc;
using namespace gs;

namespace gs {
    namespace db {
        Ref<Database> _shaderd_database;
        std::string _db_path;
    }
}

Database *db::database() {
    return _shaderd_database.get();
}

void db::setup(const gc::Ref<Database> &db) {
    _shaderd_database = db;
}
