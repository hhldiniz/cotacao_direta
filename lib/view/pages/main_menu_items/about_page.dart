import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/responsive.dart';
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

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth(context)),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0 * scale),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.attach_money, size: 72 * scale, color: Colors.amber),
              SizedBox(height: 16 * scale),
              Text(
                'Cotação Direta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24 * scale,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8 * scale),
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
              SizedBox(height: 24 * scale),
              Text(
                localization.aboutAppDescription!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16 * scale),
              ),
              SizedBox(height: 24 * scale),
              Text(
                '${localization.aboutDeveloperLabel} hhldiniz',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14 * scale),
              ),
              SizedBox(height: 8 * scale),
              Text(
                '${localization.aboutSourceCodeLabel}:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14 * scale),
              ),
              InkWell(
                onTap: () => launchUrl(
                  Uri.parse(_sourceCodeUrl),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(
                  _sourceCodeUrl,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14 * scale,
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
