import 'package:cotacao_direta/blocs/exchange_value_bloc.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/providers/exchange_value_bloc_provider.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:cotacao_direta/view/widgets/currency_refresh_scope.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExchangeRateValue extends StatefulWidget {
  final Currencies currency;
  final Color color;
  // Permite que quem exibe o valor (ex.: os cartões da tela inicial) peça um
  // tamanho maior para o destaque, sem mudar o padrão de quem já usa este
  // widget hoje.
  final double? fontSize;

  ExchangeRateValue(this.currency, {this.color = Colors.white, this.fontSize});

  @override
  State<StatefulWidget> createState() {
    return ExchangeRateValueState(currency);
  }
}

class ExchangeRateValueState extends State<ExchangeRateValue> {
  // O bloc pertence ao ExchangeValueBlocProvider, que o descarta junto com o
  // próprio State: este widget apenas o consome.
  late ExchangeValueBloc bloc;
  final _formatter = NumberFormat("#.###");
  final Currencies _currency;

  // A stream só pode ser obtida uma vez por bloc: getNextStreamController()
  // fecha e recria o StreamController se já houver um listener, então
  // chamá-la de novo a cada build (o que acontece ao trocar de aba e voltar,
  // já que o Home reconstrói a árvore) descartaria o stream em uso e
  // deixaria a tela sem receber novos valores.
  Stream<num?>? _stream;
  ExchangeValueBloc? _streamBloc;

  ExchangeRateValueState(this._currency);

  @override
  void didChangeDependencies() {
    bloc = ExchangeValueBlocProvider.of(context);
    // Depender do escopo faz este método rodar de novo — e portanto buscar a
    // cotação de novo — sempre que a tela pedir uma atualização: pull to
    // refresh, botão de atualizar, ou a volta para a aba de moedas depois de
    // trocar a contrapartida nas configurações.
    CurrencyRefreshScope.of(context);
    if (!identical(_streamBloc, bloc)) {
      _streamBloc = bloc;
      _stream = bloc.getNextStreamController();
    }
    bloc
        .retrieveCurrencyValue(_currency)
        .then((value) {
          bloc.updateValue(value);
        })
        .onError((error, stackTrace) {
          // Falhar aqui deixa o último valor na tela; sem rede e sem nada
          // salvo é o esperado.
          debugPrint("Falha ao atualizar a cotação de $_currency: $error");
          return null;
        });
    super.didChangeDependencies();
  }

  /// Enquanto a cotação não chega, o texto fica vazio; se ela não existir,
  /// mostramos "Sem Dados" em vez de um número inventado.
  String _exchangeRateLabel(
    BuildContext context,
    AsyncSnapshot<num?> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) return "";
    var value = snapshot.data;
    if (value == null || value == 0) {
      return MyAppLocalizations.of(context)!.noDataLabel!;
    }
    return _formatter.format(1 / value);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<num?>(
      stream: _stream,
      builder: (context, snapshot) => Semantics(
        label: _exchangeRateLabel(context, snapshot),
        child: Text(
          _exchangeRateLabel(context, snapshot),
          style: TextStyle(
            fontSize: widget.fontSize ?? 18 * Responsive.scaleFactor(context),
            color: widget.color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
