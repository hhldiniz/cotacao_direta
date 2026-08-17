import 'package:cotacao_direta/blocs/selected_currency_details_bloc.dart';
import 'package:cotacao_direta/model/currency.dart';
import 'package:cotacao_direta/providers/selected_currency_details_bloc_provider.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:cotacao_direta/view/widgets/bento_card.dart';
import 'package:cotacao_direta/view/widgets/charts.dart';
import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';

class SelectedCurrencyDetails extends StatefulWidget {
  final String selectedCurrencyCode;

  SelectedCurrencyDetails({Key? key, required this.selectedCurrencyCode})
    : super(key: key);

  @override
  State<SelectedCurrencyDetails> createState() =>
      _SelectedCurrencyDetailsState();
}

class _SelectedCurrencyDetailsState extends State<SelectedCurrencyDetails> {
  // O bloc pertence ao SelectedCurrencyDetailsBlocProvider, que o descarta
  // junto com o próprio State: este widget apenas o consome.
  late SelectedCurrencyDetailsBloc bloc;

  SelectedCurrencyDetailsBloc? _initializedBloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    bloc = SelectedCurrencyDetailsBlocProvider.of(context);
    if (identical(_initializedBloc, bloc)) return;
    _initializedBloc = bloc;
    // A tela já abre com o período padrão buscado, em vez de um gráfico vazio
    // esperando o primeiro toque num chip ou no botão de buscar.
    WidgetsBinding.instance.addPostFrameCallback((_) => bloc.selectPeriod(
        SelectedCurrencyDetailsBloc.defaultPeriodInDays,
        widget.selectedCurrencyCode));
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MyAppLocalizations.of(context)!;
    final _contentWidth = Responsive.contentMaxWidth(context);
    final _scale = Responsive.scaleFactor(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.selectedCurrencyCode)),
      floatingActionButton: FloatingActionButton.extended(
        // Esta tela abre em rota própria, mas a tag explícita evita o mesmo
        // conflito caso ela passe a ser embutida em outra tela.
        heroTag: "currencyHistoryFab",
        onPressed: () {
          bloc.getCurrencyHistoryData(widget.selectedCurrencyCode);
        },
        icon: const Icon(Icons.query_stats),
        label: Text(localizations.getCurrencyHistoryBtnLabel!),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _contentWidth),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16 * _scale,
              12 * _scale,
              16 * _scale,
              16 * _scale,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Os chips e os seletores de data moram no mesmo cartão: são
                // um controle só, o intervalo do gráfico. Os seletores cobrem
                // o intervalo por extenso; os chips, logo abaixo, são o
                // atalho para os períodos mais pedidos.
                BentoCard(
                  padding: EdgeInsets.all(12 * _scale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _dateField(
                              context,
                              controller: bloc.initialDateController,
                              label:
                                  localizations.currencyHistoryFromDateLabel!,
                              scale: _scale,
                              onPicked: bloc.updateInitialDate,
                            ),
                          ),
                          SizedBox(width: 12 * _scale),
                          Expanded(
                            child: _dateField(
                              context,
                              controller: bloc.endDateController,
                              label: localizations.currencyHistoryToDateLabel!,
                              scale: _scale,
                              onPicked: bloc.updateFinalDate,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12 * _scale),
                      _periodChips(localizations, _scale),
                    ],
                  ),
                ),
                SizedBox(height: 12 * _scale),
                Expanded(
                  child: BentoCard(
                    padding: EdgeInsets.fromLTRB(
                      4 * _scale,
                      20 * _scale,
                      16 * _scale,
                      8 * _scale,
                    ),
                    child: Stack(
                      children: [
                        StreamBuilder<List<Currency>>(
                          stream: bloc.currencyHistoryStream,
                          builder: (context, snapshot) {
                            final currencyList = snapshot.data;
                            if (currencyList == null || currencyList.isEmpty) {
                              return _emptyChartState(
                                context,
                                localizations,
                                _scale,
                              );
                            }
                            return SimpleLineChart(currencyList: currencyList);
                          },
                        ),
                        StreamBuilder<bool>(
                          stream: bloc.isLoadingStream,
                          initialData: false,
                          builder: (context, loadingSnapshot) {
                            if (loadingSnapshot.data == true) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Um chip por período de [SelectedCurrencyDetailsBloc.quickPeriodOptions]:
  /// tocar num deles já preenche as duas datas e busca o histórico, sem
  /// passar pelos seletores nem pelo botão de buscar.
  Widget _periodChips(MyAppLocalizations localizations, double scale) {
    return StreamBuilder<int?>(
      initialData: bloc.selectedPeriodInDays,
      stream: bloc.selectedPeriodStream,
      builder: (context, snapshot) {
        var selectedDays = snapshot.data;
        return Wrap(
          spacing: 8 * scale,
          runSpacing: 8 * scale,
          children: SelectedCurrencyDetailsBloc.quickPeriodOptions
              .map((days) => ChoiceChip(
                    label: Text(sprintf(
                        localizations.currencyHistoryPeriodOptionLabel!,
                        ["$days"])),
                    labelStyle: TextStyle(fontSize: 13 * scale),
                    visualDensity: VisualDensity.compact,
                    // Chip em pílula, para se diferenciar dos cartões
                    // (arredondados, mas em retângulo) do resto da tela.
                    shape: const StadiumBorder(),
                    selected: selectedDays == days,
                    onSelected: (_) => bloc.selectPeriod(
                        days, widget.selectedCurrencyCode),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _dateField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required double scale,
    required void Function(DateTime) onPicked,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(fontSize: 14 * scale),
      onTap: () {
        // Tira o foco para o teclado não subir: a data vem do seletor.
        FocusScope.of(context).requestFocus(FocusNode());
        showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1999),
          lastDate: DateTime.now(),
        ).then((value) {
          if (value != null) onPicked(value);
        });
      },
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        prefixIcon: Icon(Icons.calendar_today, size: 18 * scale),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BentoRadius.standard),
        ),
      ),
    );
  }

  Widget _emptyChartState(
    BuildContext context,
    MyAppLocalizations localizations,
    double scale,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24 * scale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72 * scale,
              height: 72 * scale,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(24 * scale),
              ),
              child: Icon(
                Icons.show_chart,
                size: 36 * scale,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(height: 16 * scale),
            Text(
              localizations.noDataLabel!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15 * scale,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
