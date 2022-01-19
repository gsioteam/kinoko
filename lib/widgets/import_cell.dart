

import 'package:flutter/material.dart';
import 'package:kinoko/utils/file_loader.dart';
import 'package:kinoko/utils/import_manager.dart';

import '../localizations/localizations.dart';
import 'pager/pager.dart';

class _ImportState {
  String? error;
  FileLoader? loader;
  List<String> pictures;

  _ImportState({
    this.error,
    this.loader,
    this.pictures = const [],
  });
}

class ImportCell extends StatefulWidget {
  final ImportedItem item;
  final VoidCallback? onTap;
  ImportCell({
    Key? key,
    required this.item,
    this.onTap,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ImportCellState();

}

class _ImportCellState extends State<ImportCell> {

  late Future<_ImportState> _future;

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        Material(
          color: Colors.grey.withOpacity(0.1),
          child: Padding(
            padding: EdgeInsets.only(left: 10, right: 10),
            child: FutureBuilder<_ImportState>(
                future: _future,
                builder: (context, snapshot) {
                  var data = snapshot.data;
                  Widget buildContent() {
                    if (data == null) {
                      return Text(".");
                    } else {
                      if (data.error == null) {
                        return Text(kt("n_pages").replaceFirst("{0}", data.pictures.length.toString()));
                      } else {
                        return Text(data.error!);
                      }
                    }
                  }
                  Widget? buildLeading() {
                    Widget _empty = Container(
                      width: 48,
                      height: 48,
                    );
                    if (data == null) {
                      return _empty;
                    } else if (data.error != null) {
                      return _empty;
                    } else {
                      LoaderPhotoInformation photo = LoaderPhotoInformation(data.loader, data.pictures.first);
                      return Image(
                        image: photo.getImageProvider(null),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return _empty;
                        },
                      );
                    }
                  }
                  return ListTile(
                    title: Text(widget.item.title),
                    leading: buildLeading(),
                    subtitle: buildContent(),
                    trailing: Icon(Icons.keyboard_arrow_right),
                    onTap: () {
                      if (data != null && data.error == null) {
                        widget.onTap?.call();
                      }
                    },
                  );
                }
            ),
          ),
        ),
        Divider(height: 1,)
      ],
    );
  }

  Future<_ImportState> _loadPictures() async {
    FileLoader? loader = await FileLoader.create(widget.item.path);
    if (loader == null) {
      return _ImportState(
        error: kt('unsupport_file')
      );
    } else {
      var list = await loader.getPictures().toList();
      list.sort((path1, path2) {
        return path1.compareTo(path2);
      });
      if (list.isEmpty) {
        return _ImportState(
            error: kt('no_picture_found')
        );
      } else {
        return _ImportState(
          pictures: list,
          loader: loader,
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _future = _loadPictures();
  }
}