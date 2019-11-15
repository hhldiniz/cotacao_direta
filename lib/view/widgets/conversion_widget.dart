import 'package:cotacao_direta/blocs/conversion_page_bloc.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/providers/conversion_page_bloc_provider.dart';
import 'package:cotacao_direta/util/string_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ConversionWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ConversionWidgetState();
  }
}

class ConversionWidgetState extends State<ConversionWidget> {
  ConversionPageBloc bloc;
  final _formatter = NumberFormat("#.###");

  @override
  void didChangeDependencies() {
    bloc = ConversionPageBlocProvider.of(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                      width: 60,
                      child: StreamBuilder(
                        initialData: 1,
                        stream: bloc.multiplierStream,
                        builder: (context, snapshot) => TextField(
                          decoration: InputDecoration(
                              border: OutlineInputBorder(), labelText: "Qtd"),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            bloc.updateMultiplierValue(double.parse(value));
                          },
                        ),
                      ))
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[Icon(Icons.close)],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  StreamBuilder(
                    stream: bloc.currencyFromStream,
                    initialData: Currencies.BRL,
                    builder: (context, snapshot) {
                      return DropdownButton(
                        items: Currencies.values.map((value) {
                          return DropdownMenuItem(
                            value: value,
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
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[Icon(Icons.arrow_forward)],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  StreamBuilder(
                    stream: bloc.currencyToStream,
                    initialData: Currencies.USD,
                    builder: (context, snapshot) {
                      return DropdownButton(
                        items: Currencies.values.map((value) {
                          return DropdownMenuItem(
                            value: value,
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

            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 8,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "=",
                      style: TextStyle(fontSize: 32),
                    )
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: <Widget>[
                    StreamBuilder(
                      stream: bloc.currencyLabelStream,
                      initialData: "",
                      builder: (context, snapshot) {
                        return Text(snapshot.data.toString());
                      },
                    )
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  StreamBuilder(
                    initialData: 0,
                    stream: bloc.conversionResultStream,
                    builder: (context, snapshot) => Text(
                      _formatter.format(snapshot.data),
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                ],
              )
            ],
          )
        ],
      )
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }
}
