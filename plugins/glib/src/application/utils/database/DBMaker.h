//
//  DBMaker.h
//  hirender_iOS
//
//  Created by mac on 2017/5/13.
//  Copyright © 2017年 gen. All rights reserved.
//

#ifndef DBMaker_h
#define DBMaker_h

#include <string>
#include <core/core.h>

namespace gs {
    class Query;
    class Table;
    class Database;
    namespace db {

        Database *database();
        void setup(const gc::Ref<Database> &db);
    }
}

#endif /* DBMaker_h */
