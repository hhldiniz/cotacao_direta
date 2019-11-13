import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/util/string_utils.dart';
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
      body: Container(
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
                DropdownButton(
                  items: Currencies.values.map((value) {
                    return DropdownMenuItem(
                      value: EnumValueAsString().getEnumValue(value.toString()),
                      child: Text(
                          EnumValueAsString().getEnumValue(value.toString())),
                    );
                  }).toList(),
                  onChanged: (value) {},
                  icon: Icon(Icons.arrow_downward),
                  iconSize: 24,
                  elevation: 16,
                  value: EnumValueAsString()
                      .getEnumValue(Currencies.JPY.toString()),
                )
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.arrow_forward)
              ],
            )
          ],
        ),
      ),
    );
  }
}
