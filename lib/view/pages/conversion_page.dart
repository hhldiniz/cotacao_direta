import 'package:cotacao_direta/view/widgets/conversion_widget.dart';
import 'package:flutter/material.dart';

class ConversionPage extends StatelessWidget {

  final String? pageTitle;

  ConversionPage(this.pageTitle);

  @override
  Widget build(BuildContext context) {
    // Sem botão de converter: a conversão acontece a cada mudança de
    // quantidade ou de moeda (ver ConversionWidget), então um botão só
    // repetiria o que a tela já fez sozinha.
    return Scaffold(
      appBar: AppBar(title: Text(pageTitle!)),
      body: ConversionWidget(),
    );
  }
}
