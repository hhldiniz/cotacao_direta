import 'dart:io';

class NetworkUtils{
  Future<bool> isNetworkAvailable() async{
    final result = await InternetAddress.lookup("google.com");
    try{
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch(_){
      return false;
    }
  }
}