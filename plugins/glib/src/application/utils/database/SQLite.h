//
//  SQLite.hpp
//  hirender_iOS
//
//  Created by gen on 12/05/2017.
//  Copyright © 2017 gen. All rights reserved.
//

#ifndef SQLite_hpp
#define SQLite_hpp

#include <core/Ref.h>
#include "Model.h"
#include "../../gs_define.h"

struct sqlite3;
typedef struct sqlite3 sqlite3;
namespace gs {

    CLASS_BEGIN_TN(SQLTable, Model, 1, SQLTable)

        DEFINE_STRING(table_name, TableName);
        DEFINE_FIELD(float, ver, Ver);

    public:
        static void registerFields() {
            Model::registerFields();
            ADD_FILED(SQLTable, table_name, TableName, true);
            ADD_FILED(SQLTable, ver, Ver, false);
        }

        static gc::Ref<SQLTable> getInfo(Table *table);

    CLASS_END

    CLASS_BEGIN_NV(SQLQuery, Query)

        std::string sql_sentence;
        std::string sort_bys;
        variant_vector params;

        void insertAction(const std::string &name, const gc::Variant &val, const char *action);

    protected:
        void find();

    public:
        gc::Ref<Query> equal(const std::string &name, const gc::Variant &val);
        gc::Ref<Query> andQ();
        gc::Ref<Query> greater(const std::string &name, const gc::Variant &val);
        gc::Ref<Query> less(const std::string &name, const gc::Variant &val);
        gc::Ref<Query> like(const std::string &name, const gc::Variant &val);
        gc::Ref<Query> sortBy(const std::string &name);
        gc::Ref<Query> in(const std::string &name, const gc::Array &values);
        gc::Ref<Query> in(const std::string &name, const std::string &values);
        void remove();
        _FORCE_INLINE_ SQLQuery(Table *table) : Query(table) {
        }

    CLASS_END

    CLASS_BEGIN_N(SQLite, Database)

        sqlite3 *db;
        std::string path;

        bool checkUpdate(Table *table);
        void afterUpdate(Table *table);

    protected:
        void begin();
        void action(const std::string &statement, variant_vector *params, const gc::Callback &callback);
        void end();
    public:
        SQLite() {}
        _FORCE_INLINE_ virtual gc::Ref<Query> query(Table *table) const {
            return new SQLQuery(table);
        }
        void initialize(const std::string &path);

        void processTable(Table *table);
        void update(gc::Object *model, Table *table);
        void remove(gc::Object *model, Table *table);

    CLASS_END

}

#endif /* SQLite_hpp */
