import 'package:glib/utils/git_repository.dart';
const String env_git_url = "https://github.com/gsioteam/env.git";

Map<String, String> cachedTemplates = {};
Map<String, dynamic> share_cache = Map();
GitRepository env_repo;

const String collection_download = "download";
const String collection_mark = "mark";

const String home_page_name = "home";

const String last_chapter_key = "last-chapter";
const String direction_key = "direction";
const String device_key = "device";
const String page_key = "page";

const String disclaimer_key = "disclaimer";

const String language_key = "language";

const String history_key = "history";

const String viewed_key = "viewed";

const int BOOK_INDEX = 0;
const int CHAPTER_INDEX = 1;