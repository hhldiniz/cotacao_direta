import 'dart:async';

import 'package:cotacao_direta/util/currency_colors.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/pwa_install_service.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:cotacao_direta/view/widgets/animated_list_entry.dart';
import 'package:cotacao_direta/view/widgets/bento_card.dart';
import 'package:flutter/material.dart';

/// Opção de instalar o app no aparelho, mostrada nas configurações.
///
/// Só aparece quando há mesmo o que fazer: na web, com o navegador tendo
/// aceitado o app como instalável e ele ainda não instalado. Nas outras
/// plataformas — e numa janela que já é a do app instalado — o widget não
/// ocupa espaço nenhum.
class PwaInstallCard extends StatefulWidget {
  /// Posição na lista de opções, para a animação de entrada entrar no mesmo
  /// escalonamento dos outros cartões da tela.
  final int index;

  const PwaInstallCard({super.key, required this.index});

  @override
  State<PwaInstallCard> createState() => _PwaInstallCardState();
}

class _PwaInstallCardState extends State<PwaInstallCard> {
  var _status = PwaInstallService.status;
  StreamSubscription<PwaInstallStatus>? _subscription;

  @override
  void initState() {
    super.initState();
    // O navegador costuma liberar a instalação depois de a tela já estar
    // montada, então o cartão nasce escondido e aparece quando isso acontece.
    _subscription = PwaInstallService.statusChanges.listen((status) {
      if (!mounted) return;
      setState(() => _status = status);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _install() async {
    final localization = MyAppLocalizations.of(context)!;
    final accepted = await PwaInstallService.promptInstall();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(accepted
            ? localization.pwaInstallAcceptedLabel!
            : localization.pwaInstallDismissedLabel!),
      ),
    );
  }

  /// No iOS não existe pedido de instalação para o app abrir: o melhor que dá
  /// para fazer é mostrar o caminho pelo menu do Safari.
  void _showIosInstructions() {
    final localization = MyAppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localization.pwaInstallIosDialogTitle!),
        content: Text(localization.pwaInstallIosDialogBody!),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localization.pwaInstallIosDialogCloseBtnLabel!),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIos = _status == PwaInstallStatus.manual;
    if (_status != PwaInstallStatus.promptable && !isIos) {
      return const SizedBox.shrink();
    }

    final localization = MyAppLocalizations.of(context)!;
    final scale = Responsive.scaleFactor(context);
    final onTap = isIos ? _showIosInstructions : _install;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BentoSectionTitle(localization.pwaInstallSectionLabel!),
        AnimatedListEntry(
          index: widget.index,
          child: BentoCard(
            padding: EdgeInsets.all(12 * scale),
            onTap: onTap,
            child: Row(
              children: [
                _InstallBadge(scale: scale),
                SizedBox(width: 14 * scale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        localization.pwaInstallCardLabel!,
                        style: TextStyle(fontSize: 16 * scale),
                      ),
                      SizedBox(height: 4 * scale),
                      Text(
                        isIos
                            ? localization.pwaInstallIosCardDescription!
                            : localization.pwaInstallCardDescription!,
                        style: TextStyle(
                          fontSize: 13 * scale,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8 * scale),
                FilledButton(
                  onPressed: onTap,
                  child: Text(
                    isIos
                        ? localization.pwaInstallIosBtnLabel!
                        : localization.pwaInstallBtnLabel!,
                    style: TextStyle(fontSize: 14 * scale),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12 * scale),
      ],
    );
  }
}

/// Mesmo quadradinho colorido com ícone usado pelas outras opções da tela.
class _InstallBadge extends StatelessWidget {
  final double scale;

  const _InstallBadge({required this.scale});

  @override
  Widget build(BuildContext context) {
    final size = 42.0 * scale;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CurrencyColors.cad.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14 * scale),
      ),
      child: Icon(
        Icons.install_mobile,
        color: CurrencyColors.cad,
        size: 22 * scale,
      ),
    );
  }
}
