import 'dart:typed_data';

import 'model_storage_io.dart'
    if (dart.library.js_interop) 'model_storage_web.dart';

/// Where downloaded model files are kept on the device.
///
/// Files are addressed by a relative key (`folder/file`). On Android and Linux
/// they are plain files in the app's private data folder; on the web they go
/// to the browser's Cache Storage, which, unlike the HTTP cache, is not
/// evicted on its own and survives the app being reopened offline.
abstract interface class ModelStorage {
  Future<bool> contains(String key);

  Future<Uint8List?> read(String key);

  /// Stores [bytes] under [key], replacing what was there. The write is
  /// atomic where the platform allows: a download cut halfway never leaves a
  /// truncated file behind.
  Future<void> write(String key, Uint8List bytes);

  /// Removes every file whose key starts with [folder].
  Future<void> deleteFolder(String folder);

  /// The storage of the platform the app is running on.
  factory ModelStorage() => createPlatformModelStorage();
}
