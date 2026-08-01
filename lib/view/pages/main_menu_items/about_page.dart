import 'package:cotacao_direta/util/currency_colors.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:cotacao_direta/view/widgets/bento_card.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  static const String _sourceCodeUrl =
      'https://github.com/hhldiniz/cotacao_direta';

  @override
  Widget build(BuildContext context) {
    final localization = MyAppLocalizations.of(context)!;
    final scale = Responsive.scaleFactor(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Responsive.contentMaxWidth(context),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16 * scale),
          child: Column(
            // O eixo transversal da Column é o horizontal, que aqui é
            // limitado pela largura da tela: o stretch é seguro (diferente de
            // uma Row dentro de um scroll, onde a altura é ilimitada).
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cartão de destaque, no mesmo espírito do cartão do dólar na
              // tela inicial: é o "rosto" da tela.
              BentoCard(
                accentColor: CurrencyColors.usd,
                radius: BentoRadius.hero,
                padding: EdgeInsets.symmetric(
                  horizontal: 20 * scale,
                  vertical: 28 * scale,
                ),
                child: Column(
                  children: [
                    Icon(Icons.attach_money, size: 56 * scale),
                    SizedBox(height: 12 * scale),
                    Text(
                      'Cotação Direta',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) {
                        final info = snapshot.data;
                        final version = info == null
                            ? ''
                            : '${info.version}+${info.buildNumber}';
                        return Text(
                          '${localization.aboutVersionLabel} $version',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14 * scale),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12 * scale),
              BentoCard(
                padding: EdgeInsets.all(20 * scale),
                child: Text(
                  localization.aboutAppDescription!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16 * scale, height: 1.4),
                ),
              ),
              SizedBox(height: 12 * scale),
              BentoCard(
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 20 * scale),
                    SizedBox(width: 12 * scale),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localization.aboutDeveloperLabel!,
                            style: TextStyle(
                              fontSize: 12 * scale,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            'hhldiniz',
                            style: TextStyle(fontSize: 16 * scale),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12 * scale),
              BentoCard(
                onTap: () => launchUrl(
                  Uri.parse(_sourceCodeUrl),
                  mode: LaunchMode.externalApplication,
                ),
                child: Row(
                  children: [
                    Icon(Icons.code, size: 20 * scale),
                    SizedBox(width: 12 * scale),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localization.aboutSourceCodeLabel!,
                            style: TextStyle(
                              fontSize: 12 * scale,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            _sourceCodeUrl,
                            style: TextStyle(
                              fontSize: 14 * scale,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.open_in_new,
                      size: 18 * scale,
                      color: colorScheme.outline,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
