
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glib/core/array.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/collection_data.dart';
import 'package:glib/main/project.dart';
import 'package:kinoko/utils/history_manager.dart';
import 'package:kinoko/widgets/no_data.dart';
import '../configs.dart';
import '../localizations/localizations.dart';

import 'picture_viewer.dart';
import '../utils/neo_cache_manager.dart';

class HistoryPage extends StatelessWidget {

  HistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }

}

// class HistoryPage extends StatefulWidget {
//   HistoryPage({Key key}) : super(key: key, );
//
//   @override
//   State<StatefulWidget> createState() => _HistoryPageState();
//
// }
//
// class _HistoryPageState extends State<HistoryPage> {
//
//   void onChange() async {
//     await Future.delayed(Duration(milliseconds: 100));
//     setState(() { });
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     HistoryManager().onChange = onChange;
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     HistoryManager().onChange = null;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     List<HistoryItem> items = HistoryManager().items;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(kt("history")),
//         actions: [
//           IconButton(
//               icon: Icon(Icons.clear_all),
//               onPressed: () async {
//                 bool ret = await showDialog<bool>(
//                     context: context,
//                     builder: (context) {
//                       return AlertDialog(
//                         title: Text(kt("confirm")),
//                         content: Text(kt("clear_history")),
//                         actions: [
//                           TextButton(
//                             child: Text(kt("no")),
//                             onPressed: ()=> Navigator.of(context).pop(false),
//                           ),
//                           TextButton(
//                             child: Text(kt("yes")),
//                             onPressed:()=> Navigator.of(context).pop(true),
//                           ),
//                         ],
//                       );
//                     }
//                 );
//                 if (ret == true)
//                   HistoryManager().clear();
//               }
//           )
//         ],
//       ),
//       body: items.length > 0 ? ListView.separated(
//           itemCount: items.length,
//           itemBuilder: (context, index) {
//             HistoryItem item = items[index];
//             DataItem data = item.item;
//             return ListTile(
//               tileColor: Theme.of(context).colorScheme.surface,
//               title: Text(data.title),
//               subtitle: Text(data.subtitle),
//               leading: Image(
//                 image: NeoImageProvider(
//                     uri: Uri.parse(data.picture),
//                     cacheManager: NeoCacheManager.defaultManager
//                 ),
//                 fit: BoxFit.cover,
//                 width: 56,
//                 height: 56,
//                 gaplessPlayback: true,
//               ),
//               onTap: () {
//                 enterPage(item);
//               },
//             );
//           },
//         separatorBuilder: (context, index) => Divider(height: 1,),
//       ) : NoData(),
//     );
//
//   }
//
//   void enterPage(HistoryItem historyItem) async {
//     DataItem item = historyItem.item;
//     Project project = Project.allocate(item.projectKey);
//     if (!project.isValidated) {
//       Fluttertoast.showToast(msg: kt("no_project_found"));
//       project.release();
//       return;
//     }
//     DataItemType type = item.type;
//     Context ctx;
//     if (type == DataItemType.Data) {
//       ctx = project.createCollectionContext(BOOK_INDEX, item).control();
//       ctx.autoReload = true;
//     } else {
//       Fluttertoast.showToast(msg: kt("can_not_determine_the_context_type"));
//       project.release();
//       return;
//     }
//     await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
//       return BookPage(ctx, project);
//     }));
//     ctx.release();
//     project.release();
//   }
// }