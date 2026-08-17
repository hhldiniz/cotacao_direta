import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/notification_service.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:cotacao_direta/view/widgets/bento_card.dart';
import 'package:flutter/material.dart';

/// Aviso, na tela de alertas, de que as notificações ainda não vão aparecer —
/// e o que fazer a respeito.
///
/// Existe porque um alerta cadastrado sem permissão de notificar falha em
/// silêncio: ele é conferido, é marcado como disparado, e o usuário só
/// descobre abrindo a lista. O caso mais comum é o navegador, em que a
/// permissão precisa partir de um toque — daí o botão daqui — e o do Safari no
/// iPhone e no iPad, em que não há sequer o que permitir enquanto o app não
/// for adicionado à Tela de Início.
///
/// Com a permissão concedida (ou numa plataforma sem nada a pedir) o cartão
/// não ocupa espaço nenhum.
class NotificationPermissionCard extends StatefulWidget {
  /// Injetável para os testes; em produção é sempre o serviço do app.
  final NotificationService? service;

  const NotificationPermissionCard({super.key, this.service});

  @override
  State<NotificationPermissionCard> createState() =>
      _NotificationPermissionCardState();
}

class _NotificationPermissionCardState extends State<NotificationPermissionCard>
    with WidgetsBindingObserver {
  late final NotificationService _service = widget.service ?? NotificationService();

  NotificationPermissionStatus? _status;
  var _requesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// A permissão pode ser mudada fora do app — nas configurações do site, no
  /// navegador, ou nas do sistema — e voltar para cá é o momento em que dá
  /// para perceber isso.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final status = await _service.permissionStatus();
    if (!mounted) return;
    setState(() => _status = status);
  }

  Future<void> _request() async {
    final localization = MyAppLocalizations.of(context)!;
    setState(() => _requesting = true);
    final status = await _service.requestPermission();
    if (!mounted) return;
    setState(() {
      _status = status;
      _requesting = false;
    });
    final granted = status == NotificationPermissionStatus.granted;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(granted
            ? localization.notificationPermissionGrantedLabel!
            : localization.notificationPermissionRefusedLabel!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    if (status == null ||
        status == NotificationPermissionStatus.granted ||
        status == NotificationPermissionStatus.unsupported) {
      return const SizedBox.shrink();
    }

    final localization = MyAppLocalizations.of(context)!;
    final scale = Responsive.scaleFactor(context);
    final colorScheme = Theme.of(context).colorScheme;
    // Só o "ainda não foi pedido" tem um botão: depois de uma recusa o
    // navegador não pergunta de novo, e no iOS o caminho é instalar o app.
    final canRequest = status == NotificationPermissionStatus.notRequested;
    final description = switch (status) {
      NotificationPermissionStatus.denied =>
        localization.notificationPermissionDeniedDescription!,
      NotificationPermissionStatus.requiresInstall =>
        localization.notificationPermissionIosDescription!,
      _ => localization.notificationPermissionCardDescription!,
    };

    return Padding(
      padding: EdgeInsets.only(bottom: 10 * scale),
      child: BentoCard(
        padding: EdgeInsets.all(12 * scale),
        onTap: canRequest && !_requesting ? _request : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42 * scale,
              height: 42 * scale,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14 * scale),
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                color: colorScheme.primary,
                size: 22 * scale,
              ),
            ),
            SizedBox(width: 14 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    localization.notificationPermissionCardLabel!,
                    style: TextStyle(
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4 * scale),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13 * scale,
                      height: 1.35,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (canRequest) ...[
                    SizedBox(height: 10 * scale),
                    FilledButton(
                      onPressed: _requesting ? null : _request,
                      child: Text(
                        localization.notificationPermissionBtnLabel!,
                        style: TextStyle(fontSize: 14 * scale),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
