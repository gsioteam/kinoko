
import '../core/core.dart';

enum DataItemType {
  Book,
  Chapter,
  Header,
  Unkown
}

class DataItem extends Base {

  static reg() {
    Base.reg(DataItem, "gs::DataItem", Base)
        ..constructor = ((id)=>DataItem().setID(id));
  }

  String get title => call("getTitle");
  set title(String v) => call("setTitle", argv: [v]);

  String get summary => call("getSummary");
  set summary(String v) => call("setSummary", argv: [v]);

  String get picture => call("getPicture");
  set picture(String v) => call("setPicture", argv: [v]);

  String get subtitle => call("getSubtitle");
  set subtitle(String v) => call("setSubtitle", argv: [v]);

  String get link => call("getLink");
  set link(String v) => call("setLink", argv: [v]);

  dynamic get data => call("getData");
  set data(v) => call("setData", argv: [v]);

  DataItemType get type {
    int type = call("getType");
    switch (type) {
      case 0: {
        return DataItemType.Book;
      }
      case 1: {
        return DataItemType.Chapter;
      }
      case 2: {
        return DataItemType.Header;
      }
    }
    return DataItemType.Unkown;
  }

  set type(DataItemType type) {
    int t = 0;
    switch (type) {
      case DataItemType.Book: {
        t = 0;
        break;
      }
      case DataItemType.Chapter: {
        t = 1;
        break;
      }
      case DataItemType.Header: {
        t = 2;
        break;
      }
      default: {
        break;
      }
    }
    call("setType", argv: [t]);
  }
}