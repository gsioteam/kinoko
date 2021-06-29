//
// Created by gen on 8/25/20.
//

#include "glib.h"
#include <core/Ref.h>
#include <core/Callback.h>
#include <core/Array.h>
#include <core/Map.h>
#include "utils/Platform.h"
#include "utils/GitRepository.h"
#include "utils/dart/DartRequest.h"
#include "utils/database/DBMaker.h"
#include "utils/database/SQLite.h"
#include "models/GitLibrary.h"
#include "utils/SharedData.h"
#include "main/Context.h"
#include "main/Project.h"
#include "utils/Bit64.h"
#include "main/DataItem.h"
#include "utils/Request.h"
#include "utils/Encoder.h"
#include "utils/GumboParser.h"
#include "utils/Error.h"
#include "models/KeyValue.h"
#include "utils/ScriptContext.h"
#include "models/CollectionData.h"
#include "main/LibraryContext.h"
#include "main/Settings.h"
#include "utils/dart/DartPlatform.h"
#include "utils/dart/DartBrowser.h"

using namespace gc;

extern "C" void initGlib() {
    ClassDB::reg<gc::_Map>();
    ClassDB::reg<gc::_Array>();
    ClassDB::reg<gc::_Callback>();
    ClassDB::reg<gc::FileData>();
    ClassDB::reg<gs::GitRepository>();
    ClassDB::reg<gs::DartPlatform>();
    ClassDB::reg<gs::DartRequest>();
    ClassDB::reg<gs::GitAction>();
    ClassDB::reg<gs::GitLibrary>();
    ClassDB::reg<gs::Project>();
    ClassDB::reg<gs::Bit64>();
    ClassDB::reg<gs::Context>();
    ClassDB::reg<gs::Collection>();
    ClassDB::reg<gs::DataItem>();
    ClassDB::reg<gs::Request>();
    ClassDB::reg<gs::Encoder>();
    ClassDB::reg<gs::GumboNode>();
    ClassDB::reg<gs::Error>();
    ClassDB::reg<gs::KeyValue>();
    ClassDB::reg<gs::ScriptContext>();
    ClassDB::reg<gs::CollectionData>();
    ClassDB::reg<gs::LibraryContext>();
    ClassDB::reg<gs::LibraryContext>();
    ClassDB::reg<gs::SettingItem>();
    ClassDB::reg<gs::Platform>();
    ClassDB::reg<gs::DartBrowser>();
    ClassDB::reg<gs::Browser>();
}


