import 'dart:io';

typedef AddressLookup = Future<List<InternetAddress>> Function(String host);

class NetworkUtils {
  final AddressLookup _lookup;

  NetworkUtils({AddressLookup? lookup})
      : _lookup = lookup ?? InternetAddress.lookup;

  Future<bool> isNetworkAvailable() async {
    try {
      final result = await _lookup("google.com");
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }
}
