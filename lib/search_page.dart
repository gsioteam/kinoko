
import 'package:flutter/cupertino.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:kinoko/widgets/better_refresh_indicator.dart';
import 'package:glib/main/data_item.dart';

class SearchPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SearchPageState();

}

class _SearchPageState extends State<SearchPage> {


  BetterRefreshIndicatorController controller = BetterRefreshIndicatorController();

  @override
  Widget build(BuildContext context) {
//    return NotificationListener<ScrollUpdateNotification>(
//      child: BetterRefreshIndicator(
//        child: ListView.separated(
//          padding: const EdgeInsets.all(16),
//          itemBuilder: (BuildContext context, int idx) {
//            DataItem book = books[idx];
//            return cellWithData(book, idx);
//          },
//          separatorBuilder: (BuildContext context, int index) => const Divider(),
//          itemCount: books.length,
//        ),
//        controller: controller,
//        onRefresh: onPullDownRefresh,
//      ),
//      onNotification: (ScrollUpdateNotification notification) {
//        if (notification.metrics.maxScrollExtent - notification.metrics.pixels < 20 && cooldown) {
//          widget.context.loadMore();
//          cooldown = false;
//          Future.delayed(Duration(seconds: 2)).then((value) => cooldown = true);
//        }
//        return false;
//      },
//    );
  }

}