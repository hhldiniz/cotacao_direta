import 'package:cotacao_direta/blocs/base_bloc.dart';
import 'package:cotacao_direta/blocs/configurations_page_bloc.dart';
import 'package:cotacao_direta/blocs/conversion_page_bloc.dart';
import 'package:cotacao_direta/blocs/currency_alerts_bloc.dart';
import 'package:cotacao_direta/blocs/currency_history_menu_bloc.dart';
import 'package:cotacao_direta/blocs/exchange_value_bloc.dart';
import 'package:cotacao_direta/blocs/home_bloc.dart';
import 'package:cotacao_direta/blocs/selected_currency_details_bloc.dart';
import 'package:cotacao_direta/providers/configurations_page_bloc_provider.dart';
import 'package:cotacao_direta/providers/conversion_page_bloc_provider.dart';
import 'package:cotacao_direta/providers/currency_alerts_bloc_provider.dart';
import 'package:cotacao_direta/providers/currency_history_menu_bloc_provider.dart';
import 'package:cotacao_direta/providers/exchange_value_bloc_provider.dart';
import 'package:cotacao_direta/providers/home_bloc_provider.dart';
import 'package:cotacao_direta/providers/selected_currency_details_bloc_provider.dart';
import 'package:cotacao_direta/view/widgets/widget_state_helpers/override_currency_state_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Registra a chamada de dispose em vez de fechar as streams de verdade.
mixin _DisposeSpy on BaseBloc {
  bool disposed = false;

  @override
  void dispose() => disposed = true;
}

class _SpyHomeBloc extends HomeBloc with _DisposeSpy {}

class _SpyExchangeValueBloc extends ExchangeValueBloc with _DisposeSpy {}

class _SpyConversionPageBloc extends ConversionPageBloc with _DisposeSpy {}

class _SpyConfigurationsPageBloc extends ConfigurationsPageBloc
    with _DisposeSpy {}

class _SpyCurrencyHistoryMenuBloc extends CurrencyHistoryMenuBloc
    with _DisposeSpy {}

class _SpyCurrencyAlertsBloc extends CurrencyAlertsBloc with _DisposeSpy {}

class _SpySelectedCurrencyDetailsBloc extends SelectedCurrencyDetailsBloc
    with _DisposeSpy {}

class _ProviderCase {
  final Widget Function(Widget child, BaseBloc? bloc) build;
  final BaseBloc Function(BuildContext context) read;
  final BaseBloc Function() spy;

  _ProviderCase({required this.build, required this.read, required this.spy});
}

final _cases = <String, _ProviderCase>{
  'HomeBlocProvider': _ProviderCase(
    build: (child, bloc) =>
        HomeBlocProvider(child: child, bloc: bloc as HomeBloc?),
    read: (context) => HomeBlocProvider.of(context),
    spy: () => _SpyHomeBloc(),
  ),
  'ExchangeValueBlocProvider': _ProviderCase(
    build: (child, bloc) => ExchangeValueBlocProvider(
        child: child, bloc: bloc as ExchangeValueBloc?),
    read: (context) => ExchangeValueBlocProvider.of(context),
    spy: () => _SpyExchangeValueBloc(),
  ),
  'ConversionPageBlocProvider': _ProviderCase(
    build: (child, bloc) => ConversionPageBlocProvider(
        child: child, bloc: bloc as ConversionPageBloc?),
    read: (context) => ConversionPageBlocProvider.of(context),
    spy: () => _SpyConversionPageBloc(),
  ),
  'ConfigurationsPageBlocProvider': _ProviderCase(
    build: (child, bloc) => ConfigurationsPageBlocProvider(
        child: child, bloc: bloc as ConfigurationsPageBloc?),
    read: (context) => ConfigurationsPageBlocProvider.of(context),
    spy: () => _SpyConfigurationsPageBloc(),
  ),
  'CurrencyHistoryMenuBlocProvider': _ProviderCase(
    build: (child, bloc) => CurrencyHistoryMenuBlocProvider(
        child: child, bloc: bloc as CurrencyHistoryMenuBloc?),
    read: (context) => CurrencyHistoryMenuBlocProvider.of(context),
    spy: () => _SpyCurrencyHistoryMenuBloc(),
  ),
  'CurrencyAlertsBlocProvider': _ProviderCase(
    build: (child, bloc) => CurrencyAlertsBlocProvider(
        child: child, bloc: bloc as CurrencyAlertsBloc?),
    read: (context) => CurrencyAlertsBlocProvider.of(context),
    spy: () => _SpyCurrencyAlertsBloc(),
  ),
  'SelectedCurrencyDetailsBlocProvider': _ProviderCase(
    build: (child, bloc) => SelectedCurrencyDetailsBlocProvider(
        child: child, bloc: bloc as SelectedCurrencyDetailsBloc?),
    read: (context) => SelectedCurrencyDetailsBlocProvider.of(context),
    spy: () => _SpySelectedCurrencyDetailsBloc(),
  ),
};

/// Um Row precisa de Directionality; como os testes montam árvores cruas, sem
/// MaterialApp, a direção é fornecida aqui.
Future<void> _pump(WidgetTester tester, Widget widget) => tester.pumpWidget(
    Directionality(textDirection: TextDirection.ltr, child: widget));

void main() {
  _cases.forEach((name, providerCase) {
    group(name, () {
      testWidgets('entrega o mesmo bloc a todos os descendentes',
          (WidgetTester tester) async {
        var seen = <BaseBloc>[];

        await _pump(
            tester,
            providerCase.build(
                Row(
                  children: [
                    Builder(builder: (context) {
                      seen.add(providerCase.read(context));
                      return const SizedBox();
                    }),
                    Builder(builder: (context) {
                      seen.add(providerCase.read(context));
                      return const SizedBox();
                    }),
                  ],
                ),
                null));

        expect(seen, hasLength(2));
        expect(identical(seen.first, seen.last), isTrue);
      });

      testWidgets('mantém o mesmo bloc entre rebuilds',
          (WidgetTester tester) async {
        var seen = <BaseBloc>[];
        Widget tree() => providerCase.build(Builder(builder: (context) {
              seen.add(providerCase.read(context));
              return const SizedBox();
            }), null);

        await _pump(tester, tree());
        await _pump(tester, tree());

        expect(seen.length, greaterThan(1),
            reason: "o filho precisa ter sido reconstruído");
        expect(seen.every((bloc) => identical(bloc, seen.first)), isTrue,
            reason: "um bloc novo a cada rebuild vaza o anterior");
      });

      testWidgets('não descarta o bloc que recebeu de fora',
          (WidgetTester tester) async {
        var bloc = providerCase.spy();

        await _pump(tester, providerCase.build(const SizedBox(), bloc));
        await _pump(tester, const SizedBox());

        expect((bloc as _DisposeSpy).disposed, isFalse,
            reason: "quem cria o bloc é quem descarta");
      });
    });
  });

  group('descarte do bloc criado pelo provider', () {
    testWidgets('ConversionPageBlocProvider fecha as streams do bloc',
        (WidgetTester tester) async {
      late ConversionPageBloc bloc;

      await _pump(tester,
          ConversionPageBlocProvider(child: Builder(builder: (context) {
        bloc = ConversionPageBlocProvider.of(context);
        return const SizedBox();
      })));
      await _pump(tester, const SizedBox());

      expect(() => bloc.amountSink.add(1), throwsStateError);
    });

    testWidgets('ConfigurationsPageBlocProvider fecha as streams do bloc',
        (WidgetTester tester) async {
      late ConfigurationsPageBloc bloc;

      await _pump(tester,
          ConfigurationsPageBlocProvider(child: Builder(builder: (context) {
        bloc = ConfigurationsPageBlocProvider.of(context);
        return const SizedBox();
      })));
      await _pump(tester, const SizedBox());

      expect(
          () => bloc.overrideDefaultCurrencyValueSink
              .add(OverrideCurrencyStateHelper()),
          throwsStateError);
    });
  });
}
