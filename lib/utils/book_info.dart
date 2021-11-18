
class BookInfo {
  String title;
  String? picture;
  String link;
  String? subtitle;
  String key;
  Object data;

  BookInfo({
    required this.key,
    required this.title,
    required this.link,
    required this.data,
    this.picture,
    this.subtitle,
  });

  Map toData() => {
    "key": key,
    "title": title,
    "link": link,
    "picture": picture,
    "subtitle": subtitle,
    "data": data,
  };

  BookInfo.fromData(Map data) :
        key = data["key"],
        title = data["title"],
        link = data["link"],
        picture = data["picture"],
        subtitle = data["subtitle"],
        data = data["data"];

  String get chapterName {
    if (data is Map) {
      String? title = (data as Map)["title"];
      return title ?? "";
    }
    return "";
  }
}