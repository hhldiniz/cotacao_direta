import 'package:cotacao_direta/view/widgets/conversion_widget.dart';
import 'package:flutter/material.dart';

class ConversionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            }),
      ),
      body: ConversionWidget()
    );
  }
}
