import 'package:cotacao_direta/util/ubuntu_touch_url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UbuntuTouchUrlLauncher', () {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    late List<MethodCall> calls;
    late Object? reply;

    setUp(() {
      calls = [];
      reply = true;
      messenger.setMockMethodCallHandler(UbuntuTouchUrlLauncher.channel,
          (call) async {
        calls.add(call);
        return reply;
      });
    });

    tearDown(() {
      messenger.setMockMethodCallHandler(UbuntuTouchUrlLauncher.channel, null);
    });

    test('manda a URL ao dispatcher do runner', () async {
      final launched = await UbuntuTouchUrlLauncher().launchUrl(
          'https://pub.dev/packages/url_launcher',
          const LaunchOptions(mode: PreferredLaunchMode.externalApplication));

      expect(launched, isTrue);
      expect(calls, hasLength(1));
      expect(calls.single.method, 'dispatch');
      expect(calls.single.arguments, 'https://pub.dev/packages/url_launcher');
    });

    test('devolve false quando o dispatcher recusa a URL', () async {
      reply = false;

      expect(
          await UbuntuTouchUrlLauncher()
              .launchUrl('https://example.com', const LaunchOptions()),
          isFalse);
    });

    test('só aceita os modos que abrem em outro app', () async {
      final launcher = UbuntuTouchUrlLauncher();

      expect(await launcher.supportsMode(PreferredLaunchMode.platformDefault),
          isTrue);
      expect(
          await launcher.supportsMode(PreferredLaunchMode.externalApplication),
          isTrue);
      expect(await launcher.supportsMode(PreferredLaunchMode.inAppWebView),
          isFalse);
    });

    test('considera abrível qualquer URL com esquema', () async {
      final launcher = UbuntuTouchUrlLauncher();

      expect(await launcher.canLaunch('https://example.com'), isTrue);
      expect(await launcher.canLaunch('sem esquema'), isFalse);
    });

    test('fora do Ubuntu Touch não troca a implementação', () {
      final before = UrlLauncherPlatform.instance;

      UbuntuTouchUrlLauncher.registerIfNeeded();

      expect(UrlLauncherPlatform.instance, same(before));
    });
  });
}
