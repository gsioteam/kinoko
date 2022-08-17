
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider_ex/path_provider_ex.dart';
import 'package:permission_handler/permission_handler.dart';
import '../localizations/localizations.dart';
import '../widgets/navigator.dart';

class FileUtils {
  static Future<String?> openDir(BuildContext context) async {
    var kt = lc(context);

    var status = await Permission.storage.status;
    switch (status) {
      case PermissionStatus.granted:
        break;
      default: {
        var status = await Permission.storage.request();
        if (status != PermissionStatus.granted) {
          Fluttertoast.showToast(
              msg: kt("no_permission")
          );
          return null;
        }
      }
    }
    String rootDir;
    try {
      var lists = await PathProviderEx.getStorageInfo();
      var info = lists.last;
      rootDir = info.rootDir;
    } catch (e) {
      rootDir = '/';
    }
    return Navigator.of(context).push<String>(SwitchMaterialPageRoute(
        builder: (context) {
          return FilesystemPicker(
            fsType: FilesystemType.folder,
            rootDirectory: Directory(rootDir),
            fileTileSelectMode: FileTileSelectMode.checkButton,
            onSelect: (path) {
              Navigator.of(context).pop(path);
            },
          );
        }
    ));
  }

  static Future<String?> openFile(BuildContext context) async {
    var kt = lc(context);

    var status = await Permission.storage.status;
    switch (status) {
      case PermissionStatus.granted:
        break;
      default: {
        var status = await Permission.storage.request();
        if (status != PermissionStatus.granted) {
          Fluttertoast.showToast(
              msg: kt("no_permission")
          );
          return null;
        }
      }
    }
    String rootDir;
    try {
      var lists = await PathProviderEx.getStorageInfo();
      var info = lists.last;
      rootDir = info.rootDir;
    } catch (e) {
      rootDir = '/';
    }
    return Navigator.of(context).push<String>(SwitchMaterialPageRoute(
        builder: (context) {
          return FilesystemPicker(
            fsType: FilesystemType.file,
            rootDirectory: Directory(rootDir),
            fileTileSelectMode: FileTileSelectMode.wholeTile,
            onSelect: (path) {
              Navigator.of(context).pop(path);
            },
          );
        }
    ));
  }
}