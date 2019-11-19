import 'package:cotacao_direta/providers/conversion_page_bloc_provider.dart';
import 'package:cotacao_direta/view/widgets/conversion_widget.dart';
import 'package:flutter/material.dart';

class ConversionPage extends StatelessWidget {

  final String pageTitle;

  ConversionPage(this.pageTitle);

  @override
  Widget build(BuildContext context) {
    final conversionPageBloc = ConversionPageBlocProvider.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(onPressed: (){
        conversionPageBloc.updateResult();
      }, label: Text("Converter"),
      icon: Icon(Icons.autorenew),),
      appBar: AppBar(
        title: Text(pageTitle),
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
