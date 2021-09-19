import 'package:cotacao_direta/blocs/selected_currency_details_bloc.dart';
import 'package:flutter/material.dart';

class SelectedCurrencyDetailsBlocProvider extends InheritedWidget {

  final SelectedCurrencyDetailsBloc bloc;

  SelectedCurrencyDetailsBlocProvider({Key? key, required Widget child})
      : bloc = SelectedCurrencyDetailsBloc(),
        super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => true;

  static SelectedCurrencyDetailsBloc of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SelectedCurrencyDetailsBlocProvider>()!.bloc;
}
