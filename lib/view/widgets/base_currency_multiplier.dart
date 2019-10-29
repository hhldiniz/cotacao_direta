import 'package:cotacao_direta/viewmodel/viewmodel_impl/HomeViewModelImpl.dart';
import 'package:flutter/material.dart';

class BaseCurrencyMultiplier extends StatefulWidget{

  final state = BaseCurrencyMultiplierState();

  @override
  State<StatefulWidget> createState() {
    return state;
  }

}

class BaseCurrencyMultiplierState extends State<BaseCurrencyMultiplier>{

  final _viewModel = HomeViewModelImpl();
  final _inputTextController = TextEditingController();

  @override
  void initState() {
    _inputTextController.addListener(()=> _viewModel.currencyMultiplierValue.add(_inputTextController.text));
    super.initState();
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
                      child: TextField(
                        controller: _inputTextController,
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