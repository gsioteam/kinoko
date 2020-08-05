import 'package:glib/utils/git_repository.dart';
const String env_git_url = "https://github.com/gsioteam/env.git";

Map<String, dynamic> share_cache = Map();
GitRepository env_repo;

const String collection_download = "download";
const String collection_mark = "mark";

const String home_page_name = "home";

const String direction_key = "direction";
const String device_key = "device";