import 'package:cotacao_direta/blocs/currency_alerts_bloc.dart';
import 'package:cotacao_direta/blocs/home_bloc.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/providers/ai_insights_bloc_provider.dart';
import 'package:cotacao_direta/providers/configurations_page_bloc_provider.dart';
import 'package:cotacao_direta/providers/conversion_page_bloc_provider.dart';
import 'package:cotacao_direta/providers/currency_alerts_bloc_provider.dart';
import 'package:cotacao_direta/providers/currency_history_menu_bloc_provider.dart';
import 'package:cotacao_direta/providers/home_bloc_provider.dart';
import 'package:cotacao_direta/util/background_alert_check.dart';
import 'package:cotacao_direta/util/color_utils.dart';
import 'package:cotacao_direta/util/currency_name.dart';
import 'package:cotacao_direta/util/currency_visuals.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:cotacao_direta/view/pages/conversion_page.dart';
import 'package:cotacao_direta/view/pages/main_menu_items/about_page.dart';
import 'package:cotacao_direta/view/pages/main_menu_items/ai_insights_page.dart';
import 'package:cotacao_direta/view/pages/main_menu_items/configurations_page.dart';
import 'package:cotacao_direta/view/pages/main_menu_items/currency_alerts_page.dart';
import 'package:cotacao_direta/view/widgets/currency_exchange_rate.dart';
import 'package:cotacao_direta/view/widgets/currency_rate_card.dart';
import 'package:cotacao_direta/view/widgets/currency_refresh_scope.dart';
import 'package:cotacao_direta/view/widgets/reorderable_bento_grid.dart';
// listEquals: o material.dart não reexporta tudo do foundation.
import 'package:flutter/foundation.dart';
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

  // Incrementado a cada pedido de atualização das cotações. Chega aos widgets
  // de valor pelo CurrencyRefreshScope, que os faz buscar de novo: como as
  // abas ficam sempre montadas no IndexedStack, sem isso as cotações seriam
  // buscadas uma única vez, no primeiro build de cada widget.
  var _ratesRevision = 0;

  // Garante que a busca inicial de cotação/alertas rode uma única vez: como
  // ela depende do context (localizations), não pode ir para initState, mas
  // build() roda de novo a cada troca de aba e não deve refazer a busca.
  var _initialFetchScheduled = false;

  // Moedas mostradas em bolha, escolhidas nas configurações. Começa nas moedas
  // padrão para a tela ter o que mostrar enquanto a leitura do banco não
  // termina — é a mesma lista que o app abria antes de a opção existir.
  var _homeCurrencies = HomeBloc.defaultHomeCurrencies;

  // Moeda em que as bolhas expressam suas cotações. Guardada aqui para o toque
  // numa bolha abrir a conversão no mesmo par que ela mostrava, sem esperar uma
  // leitura do banco no meio da navegação. Nula até a primeira leitura, e
  // quando a contrapartida escolhida não é uma moeda que o app conhece.
  Currencies? _counterCurrency;

  late final AnimationController _entranceAnimationController;
  late final AnimationController _refreshIconController;

  // Uma animação de entrada por posição da grade, criada sob demanda: o número
  // de bolhas depende da escolha do usuário, então não dá para montar a lista
  // toda de antemão. Ficam guardadas para não recriar (e não vazar ouvintes do
  // controlador) a cada build.
  final Map<int, CurvedAnimation> _tileScaleAnimations = {};
  final Map<int, CurvedAnimation> _tileFadeAnimations = {};

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
    _entranceAnimationController.forward();

    _refreshIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    for (var animation in [
      ..._tileScaleAnimations.values,
      ..._tileFadeAnimations.values
    ]) {
      animation.dispose();
    }
    _entranceAnimationController.dispose();
    _refreshIconController.dispose();
    super.dispose();
  }

  /// Entrada escalonada: cada posição da grade começa a animar um pouco depois
  /// da anterior. O atraso para de crescer na sexta posição, senão as últimas
  /// bolhas de uma lista longa só apareceriam no fim da animação.
  Animation<double> _entranceAnimation(
      Map<int, CurvedAnimation> cache, int index, Curve curve) {
    return cache.putIfAbsent(index, () {
      final start = (index * 0.12).clamp(0.0, 0.45);
      final end = (start + 0.55).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _entranceAnimationController,
        curve: Interval(start, end, curve: curve),
      );
    });
  }

  Widget _animatedTile(int index, Widget tile) {
    return ScaleTransition(
      scale: _entranceAnimation(
          _tileScaleAnimations, index, Curves.easeOutBack),
      child: FadeTransition(
        opacity: _entranceAnimation(_tileFadeAnimations, index, Curves.easeOut),
        child: tile,
      ),
    );
  }

  Future<void> _refreshRates(BuildContext context) async {
    setState(() {
      _isRefreshing = true;
      _ratesRevision++;
    });
    _refreshIconController.repeat();
    _loadCounterCurrencyName(context);
    _loadCounterCurrency();
    _loadHomeCurrencies();
    _checkCurrencyAlerts(context);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _refreshIconController
      ..stop()
      ..reset();
    setState(() => _isRefreshing = false);
  }

  /// Abre a tela de conversão.
  ///
  /// Com [fromCurrency], a tela abre convertendo essa moeda para a
  /// contrapartida das cotações — o mesmo par que a bolha tocada mostrava, para
  /// o toque continuar de onde o usuário estava olhando em vez de recomeçar no
  /// par padrão. Pelo botão flutuante, que não fala de nenhuma moeda em
  /// especial, vale o par padrão da tela de conversão.
  ///
  /// As moedas em bolha vão junto para o seletor da outra tela abrir com elas
  /// no topo.
  void _openConversionPage(BuildContext context, {Currencies? fromCurrency}) {
    var homeCurrencies = _homeCurrencies;
    var counterCurrency = _counterCurrency;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return ConversionPageBlocProvider(
            initialFromCurrency: fromCurrency,
            initialToCurrency: fromCurrency == null ? null : counterCurrency,
            priorityCurrencies: homeCurrencies,
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

  /// Lê a contrapartida das cotações, que é o destino da conversão aberta ao
  /// tocar numa bolha. Relida junto com o resto da tela porque a escolha pode
  /// ter mudado na aba de opções.
  Future<void> _loadCounterCurrency() async {
    var currency = await _bloc.loadCounterCurrency();
    if (!mounted || currency == _counterCurrency) return;
    setState(() => _counterCurrency = currency);
  }

  /// Primeira carga da tela.
  ///
  /// Os cartões já buscam sua cotação assim que são montados, mas nesse momento
  /// a leitura da configuração ainda está em curso. Ao terminar de resolver a
  /// contrapartida — que pode ser a moeda escolhida nas configurações, e não o
  /// real — pedimos uma releitura, para que o app abra mostrando os valores da
  /// moeda que o usuário escolheu, e não os da contrapartida padrão.
  ///
  /// A cotação de cada par vale por uma hora (CurrencyRepository), então esta
  /// segunda passada normalmente para no banco, sem ida à rede.
  Future<void> _loadInitialRates() async {
    if (!mounted) return;
    await _loadHomeCurrencies();
    if (!mounted) return;
    await _bloc.loadCounterCurrencyName(
      MyAppLocalizations.of(context)!.locale,
    );
    if (!mounted) return;
    await _loadCounterCurrency();
    if (!mounted) return;
    setState(() => _ratesRevision++);
  }

  /// Lê as moedas escolhidas nas configurações para a grade de bolhas.
  ///
  /// É relida ao voltar para esta aba porque a escolha pode ter mudado na aba
  /// de opções, que fica montada ao lado desta no IndexedStack.
  Future<void> _loadHomeCurrencies() async {
    var currencies = await _bloc.loadHomeCurrencies();
    if (!mounted) return;
    if (listEquals(currencies, _homeCurrencies)) return;
    setState(() => _homeCurrencies = currencies);
  }

  /// Confere os alertas de câmbio cadastrados contra a cotação mais recente.
  /// O app não roda em segundo plano, então esta é a checagem possível: toda
  /// vez que a tela busca cotações novas.
  void _checkCurrencyAlerts(BuildContext context) {
    final _localization = MyAppLocalizations.of(context)!;
    _alertsBloc.checkAlerts(
      notificationTitle: _localization.currencyAlertNotificationTitle!,
      // O mesmo texto da tarefa de segundo plano do Android: o aviso não pode
      // mudar conforme o app estava aberto ou não.
      notificationBody: (alert, value) =>
          currencyAlertNotificationBody(_localization, alert, value),
    );
  }

  /// Bolha de cotação de uma moeda. A cor e o ícone vêm da própria moeda, e
  /// não de uma lista fixa na tela: qualquer moeda pode virar bolha agora.
  Widget _currencyCard(BuildContext context, Currencies currency,
      {required bool hero, required double scale}) {
    final color = currencyAccentColor(currency);
    return CurrencyRateCard(
      // A chave é a moeda, e não a posição: ao mudar a escolha nas opções, é
      // ela que impede o cartão de uma moeda de reaproveitar o estado (e a
      // cotação já buscada) do cartão de outra.
      key: ValueKey(currency),
      // Tocar na bolha leva à conversão dessa moeda: ver a cotação e querer
      // saber quanto dá numa quantidade qualquer é o passo seguinte natural,
      // e antes disso ele custava abrir a conversão pelo botão flutuante e
      // escolher a moeda de novo na lista.
      onTap: () => _openConversionPage(context, fromCurrency: currency),
      hero: hero,
      color: color,
      icon: currencyIcon(currency),
      code: currencyCode(currency),
      label: currencyName(currency, Localizations.localeOf(context)),
      isRefreshing: _isRefreshing,
      valueWidget: CurrencyExchangeRate(
        currency,
        color: contrastingTextColor(circleBackgroundColor(context, color)),
        fontSize: (hero ? 32 : 20) * scale,
        showLabel: false,
      ),
    );
  }

  /// A grade de bolhas: a primeira moeda escolhida em destaque, ocupando a
  /// largura toda, e as demais em pares.
  ///
  /// Cada bolha leva à conversão da sua moeda; o botão flutuante continua
  /// abrindo a mesma tela no par padrão, para quem quer converter sem partir
  /// de nenhuma das moedas mostradas.
  ///
  /// A ordem das bolhas é a da configuração, mas pode ser mudada aqui mesmo:
  /// segurar o dedo sobre uma bolha e soltá-la sobre outra põe a arrastada
  /// naquela posição, empurrando as demais (ver [ReorderableBentoGrid]).
  Widget _buildBentoGrid(BuildContext context, double scale) {
    final localization = MyAppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16 * scale),
      child: ReorderableBentoGrid(
        itemCount: _homeCurrencies.length,
        spacing: 12 * scale,
        onReorder: _reorderHomeCurrencies,
        moveEarlierSemanticsLabel: localization.homeReorderMoveEarlierLabel,
        moveLaterSemanticsLabel: localization.homeReorderMoveLaterLabel,
        itemBuilder: (BuildContext context, int index, bool hero) =>
            _animatedTile(
          index,
          _currencyCard(context, _homeCurrencies[index],
              hero: hero, scale: scale),
        ),
      ),
    );
  }

  /// Põe a bolha de [oldIndex] na posição [newIndex] e empurra as demais.
  ///
  /// A tela muda na hora e a gravação vem depois: a ordem nova é o que o
  /// usuário acabou de fazer com o dedo, não faz sentido esperar o banco para
  /// mostrá-la. A mesma configuração alimenta a lista da aba de opções, então
  /// arrastar aqui é a mesma escolha, feita pelo outro lado.
  void _reorderHomeCurrencies(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    if (oldIndex < 0 || oldIndex >= _homeCurrencies.length) return;
    if (newIndex < 0 || newIndex >= _homeCurrencies.length) return;
    final currencies = List.of(_homeCurrencies);
    currencies.insert(newIndex, currencies.removeAt(oldIndex));
    setState(() => _homeCurrencies = currencies);
    _bloc.saveHomeCurrencies(currencies);
  }

  @override
  Widget build(BuildContext context) {
    final _localization = MyAppLocalizations.of(context)!;
    final _screenDimensions = MediaQuery.of(context);
    final _scale = Responsive.scaleFactor(context);
    _bloc = HomeBlocProvider.of(context);
    _alertsBloc = CurrencyAlertsBlocProvider.of(context);
    if (!identical(_headerStreamBloc, _bloc)) {
      _headerStreamBloc = _bloc;
      _headerStream = _bloc.getNextStreamController();
    }

    if (!_initialFetchScheduled) {
      _initialFetchScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialRates());
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _checkCurrencyAlerts(context),
      );
    }

    final pageHeader = StreamBuilder(
      builder: (BuildContext context, snapshot) {
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

    // Uma bolha por moeda escolhida nas configurações, com o atalho para a
    // conversão fechando a grade.
    final bentoGrid = _buildBentoGrid(context, _scale);

    // O toque longo que reordena a grade não se anuncia sozinho, então a tela
    // o diz — e só quando há mais de uma bolha, que é quando reordenar
    // significa alguma coisa.
    final reorderHint = _homeCurrencies.length > 1
        ? Padding(
            padding: EdgeInsets.only(
              left: 16 * _scale,
              right: 16 * _scale,
              bottom: 10 * _scale,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.drag_indicator,
                  size: 16 * _scale,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 6 * _scale),
                Flexible(
                  child: Text(
                    _localization.homeReorderHintLabel!,
                    style: TextStyle(
                      fontSize: 12 * _scale,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    final List<Widget> _widgetOptions = <Widget>[
      // O escopo avisa os widgets de cotação abaixo dele quando os valores
      // precisam ser buscados de novo.
      CurrencyRefreshScope(
        revision: _ratesRevision,
        child: RefreshIndicator(
          onRefresh: () => _refreshRates(context),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16 * _scale),
                  child: pageHeader,
                ),
                reorderHint,
                bentoGrid,
                // Espaço para o botão flutuante: ele paira sobre o fim da
                // lista, e sem esta folga cobriria o último cartão de cotação
                // quando a grade cabe inteira na tela.
                SizedBox(height: 96 * _scale),
              ],
            ),
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
            // A moeda de contrapartida pode ter mudado na aba de opções: ao
            // voltar para os cartões, tanto o texto do cabeçalho quanto os
            // valores precisam acompanhar a moeda em que as cotações passam a
            // ser mostradas. Sem isto só o cabeçalho mudava, e os números
            // continuavam os da contrapartida anterior.
            //
            // A cotação de cada par fica guardada por uma hora
            // (CurrencyRepository), então voltar para esta aba não significa ir
            // à rede de novo: quando nada mudou, a busca para no banco.
            if (index == 0) _ratesRevision++;
          });
          if (index == 0) {
            _loadCounterCurrencyName(context);
            _loadCounterCurrency();
            // As moedas em bolha podem ter mudado na aba de opções.
            _loadHomeCurrencies();
          }
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
