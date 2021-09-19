import 'package:cotacao_direta/blocs/conversion_page_bloc.dart';
import 'package:flutter/material.dart';

class ConversionPageBlocProvider extends InheritedWidget{
  final ConversionPageBloc bloc;

  ConversionPageBlocProvider({Key? key, required Widget child})
      : bloc = ConversionPageBloc(),
        super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => true;

  static ConversionPageBloc of(BuildContext context){
    return context.dependOnInheritedWidgetOfExactType<ConversionPageBlocProvider>()!.bloc;
  }
}
