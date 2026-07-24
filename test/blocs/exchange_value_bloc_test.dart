import 'package:cotacao_direta/blocs/exchange_value_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ExchangeValueBloc bloc;

  setUp(() => bloc = ExchangeValueBloc());

  group('ExchangeValueBloc', () {
    test('entrega o valor pela stream', () async {
      var stream = bloc.getNextStreamController();
      bloc.updateValue(5.42);

      expect(await stream.first, 5.42);
    });

    test('entrega null quando não há cotação', () async {
      var stream = bloc.getNextStreamController();
      bloc.updateValue(null);

      expect(await stream.first, isNull);
    });

    test('reaproveita o mesmo controller enquanto ninguém escuta', () {
      bloc.getNextStreamController();
      var controller = bloc.valueController;

      bloc.getNextStreamController();

      expect(identical(bloc.valueController, controller), isTrue);
    });

    test('troca o controller quando o anterior já tem ouvinte', () async {
      bloc.getNextStreamController().listen((_) {});
      var controller = bloc.valueController;

      bloc.getNextStreamController();

      expect(identical(bloc.valueController, controller), isFalse);
    });
  });
}
