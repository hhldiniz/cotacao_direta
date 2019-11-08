import 'package:cotacao_direta/blocs/home_bloc.dart';
import 'package:cotacao_direta/providers/home_bloc_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BaseCurrencyMultiplier extends StatefulWidget{

  final state = BaseCurrencyMultiplierState();

  @override
  State<StatefulWidget> createState() {
    return state;
  }

}

class BaseCurrencyMultiplierState extends State<BaseCurrencyMultiplier>{

  HomeBloc bloc;

  @override
  void didChangeDependencies() {
    bloc = HomeBlocProvider.of(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Column(
          children: <Widget>[
            Container(
              width: 24,
              child: StreamBuilder<String>(
                builder: (context, snapshot){
                  return Container(
                      width: 24,
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        initialValue: "1",
                        onChanged: (String text){
                          if(text.isNotEmpty)
                            bloc.updateMultiplier(text);
                        },
                        decoration: InputDecoration(errorText: snapshot.data),
                      )
                  );
                },
              ),
            )
          ],
        ),
        Column(
          children: <Widget>[
            Text("Real vale hoje", style: TextStyle(fontSize: 24),)
          ],
        )
      ],
    );
  }
}