import 'package:cotacao_direta/util/currency_colors.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:cotacao_direta/util/third_party_credits.dart';
import 'package:cotacao_direta/view/widgets/bento_card.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  static const String _sourceCodeUrl =
      'https://github.com/hhldiniz/cotacao_direta';

  /// O aviso de direito autoral do próprio app, mostrado no rodapé da tela de
  /// licenças do Flutter junto com o das dependências.
  static const String _legalese = '© 2026 hhldiniz — Licença MIT';

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
                onTap: () => _openUrl(_sourceCodeUrl),
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

              // Créditos: as licenças permissivas usadas pelas dependências
              // (MIT, BSD, Apache 2.0, MPL 2.0) obrigam a manter o aviso de
              // direito autoral em quem redistribui, e publicar o app é
              // redistribuir. A lista curada fica aqui; a exaustiva, com o
              // texto integral, sai do showLicensePage no último cartão.
              BentoSectionTitle(localization.aboutCreditsSectionLabel!),
              BentoCard(
                padding: EdgeInsets.all(20 * scale),
                child: Text(
                  localization.aboutCreditsDescription!,
                  style: TextStyle(
                    fontSize: 14 * scale,
                    height: 1.4,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(height: 12 * scale),
              _CreditsCard(
                icon: Icons.cloud_outlined,
                label: localization.aboutCreditsDataSourcesLabel!,
                credits: ThirdPartyCredits.dataSources,
              ),
              SizedBox(height: 12 * scale),
              _CreditsCard(
                icon: Icons.font_download_outlined,
                label: localization.aboutCreditsFontsAndIconsLabel!,
                credits: ThirdPartyCredits.fontsAndIcons,
              ),
              SizedBox(height: 12 * scale),
              _CreditsCard(
                icon: Icons.inventory_2_outlined,
                label: localization.aboutCreditsSoftwareLabel!,
                credits: ThirdPartyCredits.software,
              ),
              SizedBox(height: 12 * scale),
              BentoCard(
                onTap: () => _showLicenses(context),
                child: Row(
                  children: [
                    Icon(Icons.gavel_outlined, size: 20 * scale),
                    SizedBox(width: 12 * scale),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localization.aboutCreditsLicensesCardLabel!,
                            style: TextStyle(fontSize: 16 * scale),
                          ),
                          Text(
                            localization
                                .aboutCreditsLicensesCardDescription!,
                            style: TextStyle(
                              fontSize: 12 * scale,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
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

  /// A tela de licenças que o próprio Flutter monta a partir do
  /// [LicenseRegistry]: ela lista todo pacote do grafo de dependências, e não
  /// só os desta tela, com o texto integral de cada licença.
  Future<void> _showLicenses(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    // A versão vem de um Future, então o widget pode ter saído da árvore
    // enquanto ela era lida.
    if (!context.mounted) return;
    showLicensePage(
      context: context,
      applicationName: 'Cotação Direta',
      applicationVersion: '${info.version}+${info.buildNumber}',
      applicationLegalese: _legalese,
    );
  }

  Future<void> _openUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

/// Cartão de um grupo de créditos: um cabeçalho e uma linha por obra.
class _CreditsCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<ThirdPartyCredit> credits;

  const _CreditsCard({
    required this.icon,
    required this.label,
    required this.credits,
  });

  @override
  Widget build(BuildContext context) {
    final scale = Responsive.scaleFactor(context);
    final colorScheme = Theme.of(context).colorScheme;

    return BentoCard(
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 12 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20 * scale),
              SizedBox(width: 12 * scale),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          for (final credit in credits) _CreditTile(credit: credit),
        ],
      ),
    );
  }
}

/// Uma obra creditada: nome, aviso de direito autoral e licença, com toque
/// que abre a página do projeto.
class _CreditTile extends StatelessWidget {
  final ThirdPartyCredit credit;

  const _CreditTile({required this.credit});

  @override
  Widget build(BuildContext context) {
    final scale = Responsive.scaleFactor(context);
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => launchUrl(
        Uri.parse(credit.url),
        mode: LaunchMode.externalApplication,
      ),
      borderRadius: BorderRadius.circular(8 * scale),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8 * scale),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    credit.name,
                    style: TextStyle(
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2 * scale),
                  Text(
                    credit.copyright,
                    style: TextStyle(
                      fontSize: 12 * scale,
                      height: 1.3,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12 * scale),
            // A etiqueta da licença fica à direita, alinhada com o nome.
            Padding(
              padding: EdgeInsets.only(top: 2 * scale),
              child: Text(
                credit.license,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 11 * scale,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
