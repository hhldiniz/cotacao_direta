import 'dart:io';

String? platformUbuntuTouchAppId() {
  if (!Platform.isLinux) return null;
  final appId = Platform.environment['APP_ID'];
  return appId == null || appId.isEmpty ? null : appId;
}
