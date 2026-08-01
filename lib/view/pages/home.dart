import 'package:cotacao_direta/blocs/currency_alerts_bloc.dart';
import 'package:cotacao_direta/blocs/home_bloc.dart';
import 'package:cotacao_direta/notifications/update_currency_value_notification.dart';
import 'package:cotacao_direta/providers/ai_insights_bloc_provider.dart';
import 'package:cotacao_direta/providers/configurations_page_bloc_provider.dart';
import 'package:cotacao_direta/providers/conversion_page_bloc_provider.dart';
import 'package:cotacao_direta/providers/currency_alerts_bloc_provider.dart';
import 'package:cotacao_direta/providers/currency_history_menu_bloc_provider.dart';
import 'package:cotacao_direta/providers/home_bloc_provider.dart';
import 'package:cotacao_direta/util/color_utils.dart';
import 'package:cotacao_direta/util/currency_colors.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:cotacao_direta/view/pages/conversion_page.dart';
import 'package:cotacao_direta/view/pages/main_menu_items/about_page.dart';
import 'package:cotacao_direta/view/pages/main_menu_items/ai_insights_page.dart';
import 'package:cotacao_direta/view/pages/main_menu_items/configurations_page.dart';
import 'package:cotacao_direta/view/pages/main_menu_items/currency_alerts_page.dart';
import 'package:cotacao_direta/view/widgets/canadian_dollar_exchange_rate.dart';
import 'package:cotacao_direta/view/widgets/currency_rate_card.dart';
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

class HomeState extends State<Home> with TickerProviderStateMixin {
  var _selectedIndex = 0;
  late HomeBloc _bloc;
  late CurrencyAlertsBloc _alertsBloc;

  final String _pageTitle;

  var fabVisibility = true;

  // true enquanto a tela busca cotações novas (pull-to-refresh ou o botão de
  // atualizar da barra superior). Alimenta o indicador de atualização dos
  // cartões e o ícone giratório da barra: é feedback de um estado real, não
  // um dado inventado.
  var _isRefreshing = false;

  // Garante que a busca inicial de cotação/alertas rode uma única vez: como
  // ela depende do context (localizations), não pode ir para initState, mas
  // build() roda de novo a cada troca de aba e não deve refazer a busca.
  var _initialFetchScheduled = false;

  late final AnimationController _entranceAnimationController;
  late final List<Animation<double>> _tileScaleAnimations;
  late final List<Animation<double>> _tileFadeAnimations;
  late final AnimationController _refreshIconController;

  // getNextStreamController() fecha e recria o StreamController se já houver
  // um listener; chamá-la a cada build (o que acontece ao trocar de aba, já
  // que dispara setState) descartaria o stream em uso e o cabeçalho pararia
  // de receber atualizações. Por isso a stream é obtida uma única vez por
  // bloc, aqui em cache.
  Stream<String?>? _headerStream;
  HomeBloc? _headerStreamBloc;

  HomeState(this._pageTitle);

  @override
  void initState() {
    super.initState();
    _entranceAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 900),
    );
    // 5 cartões no bento (destaque + 4), com entrada escalonada.
    final ranges = List.generate(5, (index) {
      final start = index * 0.12;
      final end = (start + 0.55).clamp(0.0, 1.0);
      return (start: start, end: end);
    });
    _tileScaleAnimations = ranges
        .map(
          (range) => CurvedAnimation(
            parent: _entranceAnimationController,
            curve: Interval(range.start, range.end, curve: Curves.easeOutBack),
          ),
        )
        .toList();
    _tileFadeAnimations = ranges
        .map(
          (range) => CurvedAnimation(
            parent: _entranceAnimationController,
            curve: Interval(range.start, range.end, curve: Curves.easeOut),
          ),
        )
        .toList();
    _entranceAnimationController.forward();

    _refreshIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _entranceAnimationController.dispose();
    _refreshIconController.dispose();
    super.dispose();
  }

  Widget _animatedTile(int index, Widget tile) {
    return ScaleTransition(
      scale: _tileScaleAnimations[index],
      child: FadeTransition(
        opacity: _tileFadeAnimations[index],
        child: tile,
      ),
    );
  }

  Future<void> _refreshRates(BuildContext context) async {
    setState(() => _isRefreshing = true);
    _refreshIconController.repeat();
    _loadCounterCurrencyName(context);
    _checkCurrencyAlerts(context);
    UpdateCurrencyValueNotification().dispatch(context);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _refreshIconController
      ..stop()
      ..reset();
    setState(() => _isRefreshing = false);
  }

  void _openConversionPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return ConversionPageBlocProvider(
            child: ConversionPage(
              MyAppLocalizations.of(context)!.conversionPageTitle,
            ),
          );
        },
      ),
    );
  }

  /// Pede ao bloc o nome da moeda em que as cotações estão expressas, no idioma
  /// da tela, para o texto acima das bolhas.
  void _loadCounterCurrencyName(BuildContext context) {
    _bloc.loadCounterCurrencyName(MyAppLocalizations.of(context)!.locale);
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
    final _localization = MyAppLocalizations.of(context)!;
    final _screenDimensions = MediaQuery.of(context);
    final _scale = Responsive.scaleFactor(context);
    final _colorScheme = Theme.of(context).colorScheme;
    _bloc = HomeBlocProvider.of(context);
    _alertsBloc = CurrencyAlertsBlocProvider.of(context);
    if (!identical(_headerStreamBloc, _bloc)) {
      _headerStreamBloc = _bloc;
      _headerStream = _bloc.getNextStreamController();
    }

    if (!_initialFetchScheduled) {
      _initialFetchScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _loadCounterCurrencyName(context),
      );
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _checkCurrencyAlerts(context),
      );
    }

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
              style: TextStyle(fontSize: 22 * _scale),
              textAlign: TextAlign.center,
            ),
          );
        }
      },
      stream: _headerStream,
    );

    final usdCard = CurrencyRateCard(
      hero: true,
      color: CurrencyColors.usd,
      icon: Icons.attach_money,
      code: "USD",
      label: _localization.usdCurrencyName!,
      isRefreshing: _isRefreshing,
      valueWidget: DollarExchangeRate(
        color: contrastingTextColor(circleBackgroundColor(context, CurrencyColors.usd)),
        fontSize: 32 * _scale,
        showLabel: false,
      ),
    );

    final eurCard = CurrencyRateCard(
      color: CurrencyColors.eur,
      icon: Icons.euro,
      code: "EUR",
      label: _localization.eurCurrencyName!,
      isRefreshing: _isRefreshing,
      valueWidget: EuroExchangeRate(
        color: contrastingTextColor(circleBackgroundColor(context, CurrencyColors.eur)),
        fontSize: 20 * _scale,
        showLabel: false,
      ),
    );

    final cadCard = CurrencyRateCard(
      color: CurrencyColors.cad,
      icon: Icons.monetization_on,
      code: "CAD",
      label: _localization.cadCurrencyName!,
      isRefreshing: _isRefreshing,
      valueWidget: CanadianDollarExchangeRate(
        color: contrastingTextColor(circleBackgroundColor(context, CurrencyColors.cad)),
        fontSize: 20 * _scale,
        showLabel: false,
      ),
    );

    final jpyCard = CurrencyRateCard(
      color: CurrencyColors.jpy,
      icon: Icons.currency_yen,
      code: "JPY",
      label: _localization.jpyCurrencyName!,
      isRefreshing: _isRefreshing,
      valueWidget: YenExchangeRate(
        color: contrastingTextColor(circleBackgroundColor(context, CurrencyColors.jpy)),
        fontSize: 20 * _scale,
        showLabel: false,
      ),
    );

    // Quinto "tile" do bento: não é uma cotação, é um atalho para a
    // conversão. O InkWell/Material dá o mesmo tipo de feedback tátil ao
    // toque que os cartões de cotação têm, sem duplicar a lógica deles.
    final convertShortcutTile = Material(
      color: _colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openConversionPage(context),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16 * _scale,
            vertical: 14 * _scale,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.compare_arrows,
                color: _colorScheme.onSecondaryContainer,
                size: 20 * _scale,
              ),
              SizedBox(height: 10 * _scale),
              Text(
                _localization.convertActionBtnLabel!,
                style: TextStyle(
                  color: _colorScheme.onSecondaryContainer,
                  fontSize: 16 * _scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final bentoGrid = Padding(
      padding: EdgeInsets.symmetric(horizontal: 16 * _scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _animatedTile(0, usdCard),
          SizedBox(height: 12 * _scale),
          // O IntrinsicHeight é obrigatório aqui: a Row usa
          // CrossAxisAlignment.stretch para os dois cartões terminarem com a
          // mesma altura, mas o eixo transversal de uma Row é o vertical, que
          // dentro do SingleChildScrollView é ilimitado. Sem uma altura
          // definida, o stretch não tem o que esticar e o layout falha
          // (RenderFlex sem size, erro a cada frame).
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _animatedTile(1, eurCard)),
                SizedBox(width: 12 * _scale),
                Expanded(child: _animatedTile(2, cadCard)),
              ],
            ),
          ),
          SizedBox(height: 12 * _scale),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _animatedTile(3, jpyCard)),
                SizedBox(width: 12 * _scale),
                Expanded(child: _animatedTile(4, convertShortcutTile)),
              ],
            ),
          ),
        ],
      ),
    );

    final List<Widget> _widgetOptions = <Widget>[
      RefreshIndicator(
        onRefresh: () => _refreshRates(context),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16 * _scale),
                child: pageHeader,
              ),
              bentoGrid,
              SizedBox(height: 16 * _scale),
            ],
          ),
        ),
      ),
      Container(
        child: CurrencyHistoryMenuBlocProvider(child: CurrencyHistory()),
      ),
      Container(child: CurrencyAlertsPage()),
      Container(
        child: AiInsightsBlocProvider(child: AiInsightsPage()),
      ),
      Container(
        child: ConfigurationsPageBlocProvider(child: ConfigurationsPage()),
      ),
      Container(child: AboutPage()),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle),
        actions: [
          RotationTransition(
            turns: _refreshIconController,
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _refreshRates(context),
            ),
          ),
        ],
      ),
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
            icon: Icon(Icons.auto_awesome),
            label: _localization.aiInsightsBottomNavItemLabel,
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
          // A moeda de contrapartida pode ter mudado na aba de opções: ao
          // voltar para as bolhas, o texto do cabeçalho precisa acompanhar a
          // moeda em que as cotações passam a ser mostradas.
          if (index == 0) _loadCounterCurrencyName(context);
        },
      ),
      floatingActionButton: Visibility(
        visible: fabVisibility,
        child: FloatingActionButton.extended(
          // As abas ficam todas montadas dentro do IndexedStack, então o FAB
          // desta tela convive com o da tela de alertas na mesma rota. Sem uma
          // tag própria, os dois disputariam a tag padrão do Hero.
          heroTag: "homeConversionFab",
          onPressed: () => _openConversionPage(context),
          label: Text(_localization.conversionButtonLabel!),
          icon: Icon(Icons.compare_arrows),
        ),
      ),
      // IndexedStack mantém as 6 abas montadas o tempo todo, só alternando
      // qual fica visível. Isso evita que trocar de aba destrua e recrie o
      // estado da anterior (cotações já buscadas, animações etc.), o que
      // forçaria buscas repetidas de rede/banco toda vez que o usuário volta
      // para uma aba já visitada.
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
    );
  }
}
