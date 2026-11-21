import 'dart:js_interop';
import 'dart:typed_data';

import 'package:cotacao_direta/ai/model/model_storage.dart';
import 'package:web/web.dart' as web;

ModelStorage createPlatformModelStorage() => CacheModelStorage();

/// Model files in the browser's Cache Storage.
///
/// The cache name starts with `cotacao-direta-models`, which the app's service
/// worker leaves alone when it clears old caches on an update (see
/// web/service_worker.js). The keys are addresses under the app's own path
/// that are never requested from the network: they only name the entries.
class CacheModelStorage implements ModelStorage {
  static const String cacheName = "cotacao-direta-models-v1";

  Future<web.Cache> _open() => web.window.caches.open(cacheName).toDart;

  String _url(String key) => Uri.base.resolve("ai-models/$key").toString();

  @override
  Future<bool> contains(String key) async {
    final cache = await _open();
    return (await cache.match(_url(key).toJS).toDart) != null;
  }

  @override
  Future<Uint8List?> read(String key) async {
    final cache = await _open();
    final response = await cache.match(_url(key).toJS).toDart;
    if (response == null) return null;
    final buffer = await response.arrayBuffer().toDart;
    return buffer.toDart.asUint8List();
  }

  @override
  Future<void> write(String key, Uint8List bytes) async {
    final cache = await _open();
    // Cache.put replaces the entry in one step, so a reader sees either the
    // old file or the new one.
    await cache
        .put(
            _url(key).toJS,
            web.Response(
                bytes.toJS,
                web.ResponseInit(
                    status: 200,
                    headers: {"Content-Type": "application/octet-stream"}
                        .jsify() as web.HeadersInit)))
        .toDart;
  }

  @override
  Future<void> deleteFolder(String folder) async {
    final cache = await _open();
    final prefix = _url("$folder/");
    final requests = (await cache.keys().toDart).toDart;
    for (final request in requests) {
      if (request.url.startsWith(prefix)) await cache.delete(request).toDart;
    }
  }
}
