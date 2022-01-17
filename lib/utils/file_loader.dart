
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:path/path.dart' as p;

enum FileType {
  Folder,
  Zip,
  GZip,
  Tar,
  ZLib,
  BZip2,
  XZ,
}

bool _testPictureName(String path) {
  var ext = p.extension(path).toLowerCase();
  return ext == '.jpg' ||
      ext == '.png' ||
      ext == '.jpeg' ||
      ext == '.webp';
}

abstract class FileLoader {
  final String path;
  FileType get type;

  FileLoader._(this.path);

  static Future<FileLoader?> create(String path) async {
    File file = File(path);
    if ((await file.stat()).type == FileSystemEntityType.directory) {
      return FolderLoader(path);
    }
    var ext = p.extension(path).toLowerCase();
    switch (ext) {
      case 'zip':
        return ZipLoader(path);
      case '7z':
      case 'gz':
        return GZipLoader(path);
      case 'tar':
        return TarLoader(path);
      case 'zlib':
        return ZLibLoader(path);
      case 'xz':
        return XZLoader(path);
      case 'bz2':
        return BZip2Loader(path);
    }
    return null;
  }

  Stream<String> getPictures();
  Future<Uint8List> readFile(String path);
}

class FolderLoader extends FileLoader {
  FolderLoader(String path) : super._(path);

  @override
  Stream<String> getPictures() async* {
    Directory directory = Directory(path);
    await for (var subfile in directory.list(recursive: true)) {
      if ((await subfile.stat()).type == FileSystemEntityType.file) {
        if (_testPictureName(subfile.path)) {
          yield subfile.path.replaceFirst(path, '');
        }
      }
    }
  }

  @override
  Future<Uint8List> readFile(String path) {
    var filepath = this.path + path;
    File file  = File(filepath);
    return file.readAsBytes();
  }

  @override
  FileType get type => FileType.Folder;
}

abstract class ArchiveLoader extends FileLoader {
  late Archive _archive;
  ArchiveLoader(String path) : super._(path) {
    _ready = _setup();
  }

  late Future<void> _ready;

  Future<void> _setup();

  @override
  Stream<String> getPictures() async* {
    await _ready;
    var list = _archive.toList();
    list.sort((file1, file2) {
      return file1.name.compareTo(file2.name);
    });
    for (var file in list) {
      if (_testPictureName(file.name)) {
        yield file.name;
      }
    }
  }

  @override
  Future<Uint8List> readFile(String path) async {
    await _ready;
    var file = _archive.findFile(path);
    return file!.content;
  }

  @override
  FileType get type => FileType.Zip;
}

class ZipLoader extends ArchiveLoader {
  ZipLoader(String path) : super(path);

  @override
  Future<void> _setup() async {
    File file = File(path);
    _archive = ZipDecoder().decodeBytes(await file.readAsBytes());
  }
}

class GZipLoader extends ArchiveLoader {
  GZipLoader(String path) : super(path);

  @override
  Future<void> _setup() async {
    File file = File(path);
    _archive = TarDecoder().decodeBytes(GZipDecoder().decodeBytes(await file.readAsBytes()));
  }
}

class TarLoader extends ArchiveLoader {
  TarLoader(String path) : super(path);

  @override
  Future<void> _setup() async {
    File file = File(path);
    _archive = TarDecoder().decodeBytes(await file.readAsBytes());
  }
}

class ZLibLoader extends ArchiveLoader {
  ZLibLoader(String path) : super(path);

  @override
  Future<void> _setup() async {
    File file = File(path);
    _archive = TarDecoder().decodeBytes(ZLibDecoder().decodeBytes(await file.readAsBytes()));
  }
}

class XZLoader extends ArchiveLoader {
  XZLoader(String path) : super(path);

  @override
  Future<void> _setup() async {
    File file = File(path);
    _archive = TarDecoder().decodeBytes(XZDecoder().decodeBytes(await file.readAsBytes()));
  }
}

class BZip2Loader extends ArchiveLoader {
  BZip2Loader(String path) : super(path);

  @override
  Future<void> _setup() async {
    File file = File(path);
    _archive = TarDecoder().decodeBytes(BZip2Decoder().decodeBytes(await file.readAsBytes()));
  }
}