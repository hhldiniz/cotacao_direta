import 'package:cotacao_direta/blocs/configurations_page_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ConfigurationsPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    ConfigurationsPageBloc _bloc;
    return Column(
      children: [
        Row(
          children: [
            Switch(value: false, onChanged: (bool checked){

            })
          ],
        )
      ],
    );
  }

}