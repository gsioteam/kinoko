
import 'package:glib/core/gmap.dart';
import 'package:glib/main/data_item.dart';

extension Headers on DataItem {
  Map<String, String> get headers {
    Map<String, String> headers;
    var itemData = data;
    if (itemData is GMap) {
      var itemHeaders = itemData["headers"];
      if (itemHeaders is GMap) {
        headers = {};
        itemHeaders.forEach((key, value) {
          headers[key] = value;
        });
      }
    }
    return headers;
  }
}