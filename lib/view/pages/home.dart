import 'package:cotacao_direta/blocs/currency_alerts_bloc.dart';
import 'package:cotacao_direta/blocs/home_bloc.dart';
import 'package:cotacao_direta/notifications/update_currency_value_notification.dart';
import 'package:cotacao_direta/providers/configurations_page_bloc_provider.dart';
import 'package:cotacao_direta/providers/conversion_page_bloc_provider.dart';
import 'package:cotacao_direta/providers/currency_alerts_bloc_provider.dart';
import 'package:cotacao_direta/providers/currency_history_menu_bloc_provider.dart';
import 'package:cotacao_direta/providers/home_bloc_provider.dart';
import 'package:cotacao_direta/util/color_utils.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:cotacao_direta/view/pages/conversion_page.dart';
import 'package:cotacao_direta/view/pages/main_menu_items/about_page.dart';
import 'package:cotacao_direta/view/pages/main_menu_items/configurations_page.dart';
import 'package:cotacao_direta/view/pages/main_menu_items/currency_alerts_page.dart';
import 'package:cotacao_direta/view/widgets/canadian_dollar_exchange_rate.dart';
import 'package:cotacao_direta/view/widgets/dollar_exchange_rate.dart';
import 'package:cotacao_direta/view/widgets/euro_exchange_rate.dart';
import 'package:cotacao_direta/view/widgets/yen_exchange_rate.dart';
import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';

import 'main_menu_items/currency_history_menu.dart';

class Home extends StatefulWidget {
  final String _pageTitle;

  Home(this._pageTitle);

  @override
  State<StatefulWidget> createState() => HomeState(_pageTitle);
}

class HomeState extends State<Home> with SingleTickerProviderStateMixin {
  var _selectedIndex = 0;
  late HomeBloc _bloc;
  late CurrencyAlertsBloc _alertsBloc;

  final String _pageTitle;

  var fabVisibility = true;

  late final AnimationController _circlesAnimationController;
  late final List<Animation<double>> _circleScaleAnimations;
  late final List<Animation<double>> _circleFadeAnimations;

  HomeState(this._pageTitle);

  @override
  void initState() {
    super.initState();
    _circlesAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 900),
    );
    final ranges = List.generate(4, (index) {
      final start = index * 0.15;
      final end = (start + 0.6).clamp(0.0, 1.0);
      return (start: start, end: end);
    });
    _circleScaleAnimations = ranges
        .map(
          (range) => CurvedAnimation(
            parent: _circlesAnimationController,
            curve: Interval(range.start, range.end, curve: Curves.easeOutBack),
          ),
        )
        .toList();
    _circleFadeAnimations = ranges
        .map(
          (range) => CurvedAnimation(
            parent: _circlesAnimationController,
            curve: Interval(range.start, range.end, curve: Curves.easeOut),
          ),
        )
        .toList();
    _circlesAnimationController.forward();
  }

  @override
  void dispose() {
    _circlesAnimationController.dispose();
    super.dispose();
  }

  Widget _animatedCircle(int index, Widget circle) {
    return ScaleTransition(
      scale: _circleScaleAnimations[index],
      child: FadeTransition(
        opacity: _circleFadeAnimations[index],
        child: circle,
      ),
    );
  }

  /// Círculo de cotação com sombra (para dar profundidade) e cor de fundo
  /// já ajustada ao tema claro/escuro.
  Widget _currencyCircle(
    BuildContext context, {
    required int index,
    required Color baseColor,
    required double padding,
    required Widget child,
  }) {
    return _animatedCircle(
      index,
      Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: circleBackgroundColor(context, baseColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Future<void> _refreshRates(BuildContext context) async {
    _bloc.getSelectedOverrideCurrency();
    _checkCurrencyAlerts(context);
    UpdateCurrencyValueNotification().dispatch(context);
    await Future.delayed(const Duration(milliseconds: 400));
  }

  /// Confere os alertas de câmbio cadastrados contra a cotação mais recente.
  /// O app não roda em segundo plano, então esta é a checagem possível: toda
  /// vez que a tela busca cotações novas.
  void _checkCurrencyAlerts(BuildContext context) {
    final _localization = MyAppLocalizations.of(context)!;
    _alertsBloc.checkAlerts(
      notificationTitle: _localization.currencyAlertNotificationTitle!,
      notificationBody: (alert, value) => sprintf(
          _localization.currencyAlertNotificationBody!,
          [alert.currencyCode, value.toStringAsFixed(4)]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final _localization = MyAppLocalizations.of(context)!;
    final _screenDimensions = MediaQuery.of(context);
    final _scale = Responsive.scaleFactor(context);
    _bloc = HomeBlocProvider.of(context);
    _alertsBloc = CurrencyAlertsBlocProvider.of(context);

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _bloc.getSelectedOverrideCurrency(),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkCurrencyAlerts(context),
    );

    final pageHeader = StreamBuilder(
      builder: (BuildContext context, snapshot) {
        UpdateCurrencyValueNotification().dispatch(context);
        if (snapshot.data == null)
          return Container();
        else {
          return Container(
            width: _screenDimensions.size.width,
            child: Text(
              sprintf(_localization.homePageHeadsUpText!, [snapshot.data]),
              style: TextStyle(fontSize: 28 * _scale),
              textAlign: TextAlign.center,
            ),
          );
        }
      },
      stream: _bloc.getNextStreamController(),
    );

    final dollarExchangeRate = DollarExchangeRate(
      color: contrastingTextColor(circleBackgroundColor(context, Colors.amber)),
    );
    final euroExchangeRate = EuroExchangeRate(
      color: contrastingTextColor(
        circleBackgroundColor(context, Colors.blueAccent),
      ),
    );
    final canadianDollarExchangeRate = CanadianDollarExchangeRate(
      color: contrastingTextColor(
        circleBackgroundColor(context, Colors.deepOrange),
      ),
    );
    final yenExchangeRate = YenExchangeRate(
      color: contrastingTextColor(circleBackgroundColor(context, Colors.pink)),
    );

    final List<Widget> _widgetOptions = <Widget>[
      RefreshIndicator(
        onRefresh: () => _refreshRates(context),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: orientation == Orientation.portrait
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Column(children: <Widget>[pageHeader]),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Column(
                          children: <Widget>[
                            _currencyCircle(
                              context,
                              index: 0,
                              baseColor: Colors.amber,
                              padding: 40.0 * _scale,
                              child: dollarExchangeRate,
                            ),
                          ],
                        ),
                        Column(
                          children: <Widget>[
                            _currencyCircle(
                              context,
                              index: 1,
                              baseColor: Colors.blueAccent,
                              padding: 40.0 * _scale,
                              child: euroExchangeRate,
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Column(
                          children: <Widget>[
                            _currencyCircle(
                              context,
                              index: 2,
                              baseColor: Colors.deepOrange,
                              padding: 60.0 * _scale,
                              child: canadianDollarExchangeRate,
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        _currencyCircle(
                          context,
                          index: 3,
                          baseColor: Colors.pink,
                          padding: 33.0 * _scale,
                          child: yenExchangeRate,
                        ),
                      ],
                    ),
                  ],
                )
              : Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Column(children: <Widget>[pageHeader]),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Column(
                          children: <Widget>[
                            _currencyCircle(
                              context,
                              index: 0,
                              baseColor: Colors.amber,
                              padding: 40.0 * _scale,
                              child: dollarExchangeRate,
                            ),
                          ],
                        ),
                        Column(
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(top: 100.0 * _scale),
                              child: _currencyCircle(
                                context,
                                index: 1,
                                baseColor: Colors.blueAccent,
                                padding: 40.0 * _scale,
                                child: euroExchangeRate,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: <Widget>[
                            _currencyCircle(
                              context,
                              index: 2,
                              baseColor: Colors.deepOrange,
                              padding: 40.0 * _scale,
                              child: canadianDollarExchangeRate,
                            ),
                          ],
                        ),
                        Column(
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(top: 100 * _scale),
                              child: _currencyCircle(
                                context,
                                index: 3,
                                baseColor: Colors.pink,
                                padding: 35.0 * _scale,
                                child: yenExchangeRate,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
      Container(
        child: CurrencyHistoryMenuBlocProvider(child: CurrencyHistory()),
      ),
      Container(child: CurrencyAlertsPage()),
      Container(
        child: ConfigurationsPageBlocProvider(child: ConfigurationsPage()),
      ),
      Container(child: AboutPage()),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(_pageTitle)),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: _localization.mainCurrenciesBottomNavItemLabel,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: _localization.currencyHistoryBottomNavItemLabel,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: _localization.currencyAlertsBottomNavItemLabel,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: _localization.getConfigBottomNavItemLabel,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: _localization.aboutBottomNavItemLabel,
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            fabVisibility = index == 0;
            _selectedIndex = index;
          });
        },
      ),
      floatingActionButton: Visibility(
        visible: fabVisibility,
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return ConversionPageBlocProvider(
                    child: ConversionPage(_localization.conversionPageTitle),
                  );
                },
              ),
            );
          },
          label: Text(_localization.conversionButtonLabel!),
          icon: Icon(Icons.compare_arrows),
        ),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
    );
  }
}
