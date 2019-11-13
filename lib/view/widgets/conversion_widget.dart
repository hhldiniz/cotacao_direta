import 'package:cotacao_direta/blocs/conversion_page_bloc.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/providers/conversion_page_bloc_provider.dart';
import 'package:cotacao_direta/util/string_utils.dart';
import 'package:flutter/material.dart';

class ConversionWidget extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return ConversionWidgetState();
  }

}

class ConversionWidgetState extends State<ConversionWidget>{

  ConversionPageBloc bloc;

  @override
  void didChangeDependencies() {
    bloc = ConversionPageBlocProvider.of(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 60,
                child: TextField(),
              )
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.close)
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              StreamBuilder(
                stream: bloc.currencyFromStream,
                initialData: EnumValueAsString().getEnumValue(Currencies.JPY.toString()),
                builder: (context, snapshot){
                  return DropdownButton(
                    items: Currencies.values.map((value) {
                      return DropdownMenuItem(
                        value: EnumValueAsString().getEnumValue(value.toString()),
                        child: Text(
                            EnumValueAsString().getEnumValue(value.toString())),
                      );
                    }).toList(),
                    onChanged: (value) {
                      bloc.updateFromCurrency(value);
                    },
                    icon: Icon(Icons.arrow_downward),
                    iconSize: 24,
                    elevation: 16,
                    value: snapshot.data,
                  );
                },
              )

            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.arrow_forward)
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              StreamBuilder(
                stream: bloc.currencyToStream,
                initialData: EnumValueAsString().getEnumValue(Currencies.JPY.toString()),
                builder: (context, snapshot){
                  return DropdownButton(
                    items: Currencies.values.map((value) {
                      return DropdownMenuItem(
                        value: EnumValueAsString().getEnumValue(value.toString()),
                        child: Text(
                            EnumValueAsString().getEnumValue(value.toString())),
                      );
                    }).toList(),
                    onChanged: (value) {
                      bloc.updateToCurrency(value);
                    },
                    icon: Icon(Icons.arrow_downward),
                    iconSize: 24,
                    elevation: 16,
                    value: snapshot.data,
                  );
                },
              )
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("=", style: TextStyle(fontSize: 32),)
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              StreamBuilder(
                initialData: 0,
                stream: bloc.conversionResultStream,
                builder: (context, snapshot)=> Text(snapshot.data.toString(), style: TextStyle(fontSize: 18),),
              )
            ],
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }

}