//
// Created by gen on 7/1/2020.
//

#ifndef ANDROID_BOOKDATA_H
#define ANDROID_BOOKDATA_H


#include "../utils/database/Model.h"
#include "../gs_define.h"

namespace gs {
    class Book;

    CLASS_BEGIN_TN(BookData, Model, 1, BookData)

        DEFINE_STRING(title, Title);
        DEFINE_STRING(summary, Summary);
        DEFINE_STRING(picture, Picture);
        DEFINE_STRING(subtitle, Subtitle);
        DEFINE_STRING(link, Link);
        DEFINE_STRING(data, Data);
        DEFINE_STRING(project_key, ProjectKey);
        DEFINE_STRING(subitems, SubItems);
        DEFINE_FIELD(int, type, Type);
        DEFINE_FIELD(int, flag, Flag);
        DEFINE_FIELD(long long, date, Date);

    public:
        static void registerFields() {
            Model::registerFields();
            ADD_FILED(BookData, title, Title, false);
            ADD_FILED(BookData, summary, Summary, false);
            ADD_FILED(BookData, picture, Picture, false);
            ADD_FILED(BookData, subtitle, Subtitle, false);
            ADD_FILED(BookData, link, Link, false);
            ADD_FILED(BookData, data, Data, false);
            ADD_FILED(BookData, project_key, ProjectKey, true);
            ADD_FILED(BookData, subitems, SubItems, false);
            ADD_FILED(BookData, type, Type, false);
            ADD_FILED(BookData, flag, Flag, false);
            ADD_FILED(BookData, date, Date, false);
        }

        static float version() {
            return 1;
        }

        BookData();

    CLASS_END
}


#endif //ANDROID_BOOKDATA_H
