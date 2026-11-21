import 'dart:io';
import 'dart:typed_data';

import 'package:cotacao_direta/ai/model/model_storage.dart';
import 'package:cotacao_direta/util/ubuntu_touch.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' show getDatabasesPath;

ModelStorage createPlatformModelStorage() => FileModelStorage();

/// Model files as plain files under a `models` folder.
class FileModelStorage implements ModelStorage {
  /// Root folder; resolved from the platform when not given. The tests pass a
  /// temporary folder.
  final Future<Directory> Function() _root;

  FileModelStorage({Future<Directory> Function()? root})
      : _root = root ?? _platformRoot;

  /// The application id of the Linux build (linux/CMakeLists.txt), which
  /// also names its folder under `$XDG_DATA_HOME`.
  static const String linuxApplicationId = "io.github.hhldiniz.cotacao_direta";

  /// Android: `files/models` in the app's private data folder — the sibling of
  /// the `databases` folder sqflite already resolves — left out of the system
  /// backup (see android/app/src/main/res/xml/). Ubuntu Touch: the package's
  /// own folder under `$XDG_DATA_HOME`, the only place the AppArmor
  /// confinement lets the app write to — the same one the launcher runs the
  /// app from. Linux and Flatpak (where `$XDG_DATA_HOME` is already the
  /// sandbox's own): the app's XDG data folder.
  ///
  /// Resolved here rather than through path_provider, whose Android side
  /// brings a JNI plugin that would also have to be built natively for Linux,
  /// Flatpak and the Ubuntu Touch click.
  static Future<Directory> _platformRoot() async {
    if (Platform.isAndroid) {
      final databases = await getDatabasesPath();
      return Directory(p.join(p.dirname(databases), "files", "models"));
    }
    final dataHome = Platform.environment["XDG_DATA_HOME"] ??
        p.join(Platform.environment["HOME"] ?? ".", ".local", "share");
    final appId = ubuntuTouchAppId;
    final folder = appId != null ? appId.split("_").first : linuxApplicationId;
    return Directory(p.join(dataHome, folder, "models"));
  }

  Future<File> _file(String key) async =>
      File(p.join((await _root()).path, p.joinAll(key.split("/"))));

  @override
  Future<bool> contains(String key) async => (await _file(key)).exists();

  @override
  Future<Uint8List?> read(String key) async {
    final file = await _file(key);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  @override
  Future<void> write(String key, Uint8List bytes) async {
    final file = await _file(key);
    await file.parent.create(recursive: true);
    final partial = File("${file.path}.part");
    await partial.writeAsBytes(bytes, flush: true);
    await partial.rename(file.path);
  }

  @override
  Future<void> deleteFolder(String folder) async {
    final directory =
        Directory(p.join((await _root()).path, p.joinAll(folder.split("/"))));
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}
