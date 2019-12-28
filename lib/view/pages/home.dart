import 'package:cotacao_direta/providers/conversion_page_bloc_provider.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/view/pages/conversion_page.dart';
import 'package:cotacao_direta/view/widgets/canadian_dollar_exchange_rate.dart';
import 'package:cotacao_direta/view/widgets/dollar_exchange_rate.dart';
import 'package:cotacao_direta/view/widgets/euro_exchange_rate.dart';
import 'package:cotacao_direta/view/widgets/yen_exchange_rate.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Home extends StatefulWidget{


  final String _pageTitle;

  Home(this._pageTitle);

  @override
  State<StatefulWidget> createState() => HomeState(_pageTitle);
}

class HomeState extends State<Home>{
  final dollarExchangeRate = DollarExchangeRate();
  final euroExchangeRate = EuroExchangeRate();
  final canadianDollarExchangeRate = CanadianDollarExchangeRate();
  final yenExchangeRate = YenExchangeRate();
  var _selectedIndex = 0;

  final String _pageTitle;

  HomeState(this._pageTitle);

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final _localization = MyAppLocalizations.of(context);
    final pageHeader = Text(_localization.homePageHeadsUpText, style: TextStyle(fontSize: 28),);

    final List<Widget> _widgetOptions = <Widget>[
      Container(
        child: orientation == Orientation.portrait
            ? Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    pageHeader
                  ],
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.all(40.0),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: Colors.amber),
                      child: dollarExchangeRate,
                    ),
                  ],
                ),
                Column(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.all(40.0),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blueAccent),
                      child: euroExchangeRate,
                    )
                  ],
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.all(60.0),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.deepOrange),
                      child: canadianDollarExchangeRate,
                    )
                  ],
                )
              ],
            ),
            Row(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(33.0),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: Colors.pink),
                  child: yenExchangeRate,
                )
              ],
            )
          ],
        )
            : Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    pageHeader
                  ],
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.all(40.0),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: Colors.amber),
                      child: dollarExchangeRate,
                    ),
                  ],
                ),
                Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(top: 100.0),
                      child: Container(
                        padding: EdgeInsets.all(40.0),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blueAccent),
                        child: euroExchangeRate,
                      ),
                    )
                  ],
                ),
                Column(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.all(40.0),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.deepOrange),
                      child: canadianDollarExchangeRate,
                    )
                  ],
                ),
                Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(top: 100),
                      child:
                      Container(
                        padding: EdgeInsets.all(35.0),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: Colors.pink),
                        child: yenExchangeRate,
                      ),
                    )

                  ],
                )
              ],
            )
          ],
        ),
      ),
      Container(
        child: Text("histórico"),
      ),
      Container(
        child: Text("sobre"),
      )
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.attach_money),
              title: Text(_localization.mainCurrenciesBottomNavItemLabel)
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.history),
              title: Text(_localization.currencyHistoryBottomNavItemLabel)
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.short_text),
            title: Text(_localization.aboutBottomNavItemLabel)
          )
        ],
        currentIndex: _selectedIndex,
        onTap: (index){
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: (){
        Navigator.of(context).push(MaterialPageRoute(builder: (context){
          return ConversionPageBlocProvider(
            child: ConversionPage(_localization.conversionPageTitle),
          );
        }));
      }, label: Text(_localization.conversionButtonLabel), icon: Icon(Icons.compare_arrows),),
      body: _widgetOptions.elementAt(_selectedIndex),
    );
  }

}
