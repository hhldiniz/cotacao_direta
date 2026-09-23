import 'ubuntu_touch_io.dart'
    if (dart.library.js_interop) 'ubuntu_touch_web.dart';

/// O identificador do app no Ubuntu Touch, ou null fora dele.
///
/// O pacote .click (ver ubuntu_touch/) roda o mesmo build do Linux Desktop,
/// então não existe um Platform.isUbuntuTouch: quem denuncia o sistema é o
/// APP_ID que o Lomiri exporta para todo app que ele lança, no formato
/// `<pacote>_<hook>_<versão>` (aqui, `cotacaodireta.hhldiniz_cotacaodireta_…`).
/// Na web é sempre null.
String? get ubuntuTouchAppId => platformUbuntuTouchAppId();

/// Se o app está rodando dentro do Lomiri, o shell do Ubuntu Touch.
bool get isUbuntuTouch => ubuntuTouchAppId != null;
